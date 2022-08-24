extends Node

################################################
################### SIGNALS ####################
################################################

signal ngrok_found(status)
signal auth_request(params)
signal auth_code_set
signal auth_complete
signal user_id_found

################################################
################## CONSTANTS ###################
################################################

const __ngrok_url : String = "http://127.0.0.1:4040/api/tunnels"
const __twitch_token_URI : String = "https://id.twitch.tv/oauth2/token"
const __twitch_auth_URI : String = "https://id.twitch.tv/oauth2/authorize?"
const __twitch_auth_check : String = "https://id.twitch.tv/oauth2/validate"
const __twitch_user_URI : String = "https://api.twitch.tv/helix/users"
const check_string : String = "D4ver1noeSchm@ver!noe"

################################################
################### PUBLIC #####################
################################################

var app_token : String
var user_token : String
var user_id : String
var auth_file : UserTokens = null
var ngrok_endpoint : String = ""
var key
var cert

################################################
################### PRIVATE ####################
################################################

var __endpoint_name : String = "/auth"
var __callback_endpoint : String = ""
var __http_response = null
var __timeout_timer : Timer = Timer.new()
var __was_cancelled : bool = false
var __auth_code : String = ""
var __app_token : String = ""
var __user_token : String = ""
var __refresh_token : String = ""
var __validate_timer : Timer = Timer.new()


func _ready() -> void:
	# For SSL

	var crypto = Crypto.new()
	key = crypto.generate_rsa(4096)
	cert = load("res://certificates/ca-certificates.crt")
	
	
	self.connect("auth_request", self, "__handle_auth")
	
	# Timeout parameter in the HTTPRequest class seems to not work, so implementing my own
	# hacky solution
	__timeout_timer.wait_time = 0.5
	__timeout_timer.one_shot = true
	__timeout_timer.connect("timeout", self, "__http_timeout")
	self.add_child(__timeout_timer)
	
	# Create a timer for automatically call token validation every hour, as per Twitch guidelines
	__validate_timer.wait_time = 3555 # 5 seconds less than an hour to ensure always checking every hour
	__validate_timer.one_shot = false
	__validate_timer.connect("timeout", self, "__check_tokens")
	self.add_child(__validate_timer)
	
	# Ensure ngrok is set up
	__get_ngrok_endpoint()
	yield(self, "ngrok_found")
	__callback_endpoint = ngrok_endpoint + __endpoint_name
	var endpoint_len = __callback_endpoint.length()
	Console.log("Alert server callback endpoint: %s" % __endpoint_name)
	
	# If ngrok fails, don't ask for auth
	if __callback_endpoint != __endpoint_name:
		var file = File.new()
		# If user token doesn't exist, request auth and get user token
		var test = !file.file_exists("res://auth.res")
		if !file.file_exists("res://auth.res"):
			__request_user_auth()
			Console.log("User auth requested.")
			
			yield(self, "auth_code_set")
			Console.log("Auth code set!")
			
			yield(self.__get_user_token(), "completed")
			user_token = __user_token
			
			__save_auth_file()
		else:
			yield(self.__load_auth_file(), "completed")
		
		# After user tokens are authed and ready, get the app token
		yield(self.__get_app_token(), "completed")
		app_token = __app_token
		
		__validate_timer.start()
		
		self.emit_signal("auth_complete")
		
		__get_user_info()


func __get_ngrok_endpoint() -> void:
	var __http_request = HTTPRequest.new()
	self.add_child(__http_request)
	
	__was_cancelled = false
	var custom_header : PoolStringArray = ["Content-Type: application/json"]
	var error = __http_request.request(__ngrok_url, custom_header)
	__timeout_timer.start()
	
	if error != OK:
		push_error("An error occurred when probing ngrok.")
		
	var response = yield(__http_request, "request_completed")
	
	if !__was_cancelled:
		__timeout_timer.stop()
		__parse_response(response[0], response[1], response[2], response[3])
		
		var url = __http_response["tunnels"][0].public_url
		ngrok_endpoint = url.replace("http://", "https://")
		var ngrok_len = ngrok_endpoint.length()
		Console.log("ngrok endpoint: %s***%s" % [ngrok_endpoint.left(13), ngrok_endpoint.right(ngrok_len-14)])
		self.emit_signal("ngrok_found", Status.SUCCESS)
	else:
		__get_ngrok_endpoint()


func __request_user_auth() -> void:
	# Get scope string
	var subs = SubHelper.new()
	var scope = subs.get_basic_scope()
	var scope_string : String = scope.scope_string
	
	# Open webpage and ask user to authenticate
	# TODO save token and refresh
	
	var params : String = "response_type=code"
	params += "&client_id=%s" % OS.get_environment("TWITCH_CLIENT_ID")
	params += "&redirect_uri=%s" % __callback_endpoint
	params += "&scope=%s" % scope_string.replace(" ", "+").replace(":", "%3A")
	params += "&state=%s" % check_string
	
	OS.shell_open(__twitch_auth_URI + params)
	Console.log("Requesting user auth")
	
	subs.queue_free()


func __parse_response(result, response_code, header, body):
	__http_response = parse_json(body.get_string_from_utf8())


func __http_timeout() -> void:
	__was_cancelled = true
	self.emit_signal("ngrok_found", Status.ERROR)


func __handle_auth(params : Dictionary) -> void:
	if params.state != check_string:
		push_error("State string mismatch! ABORT! ABORT!")
	
	__auth_code = params.code
	self.emit_signal("auth_code_set")


func __get_app_token() -> void:
	
	var __http_request = HTTPRequest.new()
	self.add_child(__http_request)
	
	# Since scope was set with the authorize call, we only need an app token here
	var parameters := {
		"client_id": OS.get_environment("TWITCH_CLIENT_ID"),
		"client_secret": OS.get_environment("TWITCH_CLIENT_SECRET"),
		"grant_type": "client_credentials"
	}
	
	var http_client = HTTPClient.new()
	var post_params : String = http_client.query_string_from_dict(parameters)
	
	
	var post = HTTPClient.METHOD_POST
	
	__http_request.request(__twitch_token_URI, [], true, post, post_params)
	
	Console.log("Requesting app token")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	
	__app_token = body["access_token"]
	Console.log("App token received.")
	
	Console.log("Checking app token validity")
	__check_token(__app_token)


func __get_user_token() -> void:
	
	var __http_request = HTTPRequest.new()
	self.add_child(__http_request)
	
	# Since scope was set with the authorize call, we only need an app token here
	var parameters := {
		"client_id": OS.get_environment("TWITCH_CLIENT_ID"),
		"client_secret": OS.get_environment("TWITCH_CLIENT_SECRET"),
		"code": __auth_code,
		"grant_type": "authorization_code",
		"redirect_uri": __callback_endpoint
	}
	
	var http_client = HTTPClient.new()
	var post_params : String = http_client.query_string_from_dict(parameters)
	
	
	var post = HTTPClient.METHOD_POST
	
	__http_request.request(__twitch_token_URI, [], true, post, post_params)
	
	Console.log("Requesting user token")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	
	__user_token = body["access_token"]
	__refresh_token = body["refresh_token"]
	
	Console.log("User token received.")
	
	Console.log("Checking user token validity")
	__check_token(__user_token)


func __check_token(token : String) -> void:
	var __http_request = HTTPRequest.new()
	self.add_child(__http_request)
	
	var custom_header : PoolStringArray = ["Authorization: OAuth " + token]
	var error = __http_request.request(__twitch_auth_check, custom_header)
#	__timeout_timer.start()
	
	if error != OK:
		push_error("An error occurred when validating the token.")
	
	var response = yield(__http_request, "request_completed")
	
#	if response[]
	var statusCode = response[1]
	
	if statusCode == 401:
		Console.log("Token invalid. Requesting new token.")
		match token:
			__app_token:
				__get_app_token()
			__user_token:
				__refresh_token()
	else:
		Console.log("Token valid!")


func __parse_body(response) -> Dictionary:
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	return body


func __check_tokens() -> void:
	Console.log("Checking app token validity")
	__check_token(__app_token)
	
	Console.log("Checking user token validity")
	__check_token(__user_token)


func __get_user_info() -> void:
	var __http_request = HTTPRequest.new()
	self.add_child(__http_request)
	
	# No parameters needed, user is looked up by bearer token
	var headers = [
		"Authorization: Bearer %s" % __user_token,
		"Client-Id: %s" % OS.get_environment("TWITCH_CLIENT_ID")]
	
	__http_request.request(__twitch_user_URI, headers)
	
	Console.log("Requesting user info...")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
#	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result["data"][0]
	
	user_id = body["id"]
	Console.log("Welcome, %s" % body["display_name"])
	
	self.emit_signal("user_id_found")


func __refresh_token() -> void:
	var __http_request = HTTPRequest.new()
	var __http_client = HTTPClient.new()
	self.add_child(__http_request)
	
	# Since scope was set with the authorize call, we only need an app token here
	var post_body = {
		"client_id": OS.get_environment("TWITCH_CLIENT_ID"),
		"client_secret": OS.get_environment("TWITCH_CLIENT_SECRET"),
		"grant_type": "refresh_token",
		"refresh_token": __refresh_token.percent_encode()
	}
	
	var headers := [
		'Content-Type: application/x-www-form-urlencoded'
	]
	
	var post = __http_client.METHOD_POST
	post_body = __http_client.query_string_from_dict(post_body)
	
	__http_request.request(__twitch_token_URI, headers, true, post, post_body)
	
	Console.log("Requesting refreshed user token")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	
	__user_token = body["access_token"]
	__refresh_token = body["refresh_token"]
	
	__save_auth_file()
	
	Console.log("New user token received.")
	
	Console.log("Checking user token validity")
	__check_token(__user_token)


func __save_auth_file() -> void:
	auth_file = UserTokens.new()
	auth_file.user_token = __user_token
	auth_file.refresh_token = __refresh_token
	ResourceSaver.save("res://auth.res", auth_file)


func __load_auth_file() -> void:
	auth_file = ResourceLoader.load("res://auth.res")
	__user_token = auth_file.user_token
	__refresh_token = auth_file.refresh_token
	yield(self.__check_token(__user_token), "completed")

func check_status(body: Array, func_to_redo: FuncRef) -> void:
	if body[1] != 401:
		pass
	else:
		__request_user_auth()
		Console.log("User auth requested.")
		
		yield(self, "auth_code_set")
		Console.log("Auth code set!")
		
		yield(self.__get_user_token(), "completed")
		user_token = __user_token
		
		# After user tokens are authed and ready, get the app token
		yield(self.__get_app_token(), "completed")
		app_token = __app_token
		
		__save_auth_file()
	
		func_to_redo.call_func()
