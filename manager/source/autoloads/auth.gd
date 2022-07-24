extends Node

################################################
################### SIGNALS ####################
################################################

signal __ngrok_found(status)
signal auth_granted(params)
signal auth_code_set
signal auth_complete

################################################
################## CONSTANTS ###################
################################################

const __ngrok_url = "http://127.0.0.1:4040/api/tunnels"
const __twitch_token_URI = "https://id.twitch.tv/oauth2/token"
const __twitch_auth_URI = "https://id.twitch.tv/oauth2/authorize?"
const __twitch_auth_check = "https://id.twitch.tv/oauth2/validate"
const __check_string = "D4ver1noeSchm@ver!noe"

################################################
################### PUBLIC #####################
################################################

var app_token : String
var user_token : String

################################################
################### PRIVATE ####################
################################################

var __endpoint_name : String = "/auth"
var __callback_endpoint : String = ""
var __ngrok_endpoint : String = ""
var __http_response = null
var __timeout_timer : Timer = Timer.new()
var __was_cancelled : bool = false
var __auth_code : String = ""
var __app_token : String = ""
var __user_token : String = ""
var __validate_timer : Timer = Timer.new()


func _ready() -> void:
	self.connect("auth_granted", self, "__handle_auth")
	
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
		
	__get_ngrok_endpoint()
	yield(self, "__ngrok_found")
	__callback_endpoint = __ngrok_endpoint + __endpoint_name
	print("Alert server callback endpoint: %s" % __callback_endpoint)
	if __callback_endpoint != __endpoint_name:
		__request_user_auth()
		print("User auth requested.")
		
		yield(self, "auth_code_set")
		print("Auth code set!")
		
		yield(self.__get_app_token(), "completed")
		app_token = __app_token
		
		yield(self.__get_user_token(), "completed")
		user_token = __user_token
		
		__validate_timer.start()
		
		self.emit_signal("auth_complete")


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
		__ngrok_endpoint = url.replace("http://", "https://")
		print("ngrok endpoint: %s" % __ngrok_endpoint)
		self.emit_signal("__ngrok_found", Status.SUCCESS)
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
	params += "&state=%s" % __check_string
	
	OS.shell_open(__twitch_auth_URI + params)
	print("Requesting user auth")
	
	subs.queue_free()


func __parse_response(result, response_code, headers, body):
	__http_response = parse_json(body.get_string_from_utf8())


func __http_timeout() -> void:
	__was_cancelled = true
	self.emit_signal("__ngrok_found", Status.ERROR)


func __handle_auth(params : Dictionary) -> void:
	if params.state != __check_string:
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
	
	print("Requesting app token")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	
	__app_token = body["access_token"]
	print("App token received.")
	
	print("Checking app token validity")
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
	
	print("Requesting user token")
	
	var response = yield(__http_request, "request_completed")
	
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	
	__user_token = body["access_token"]
	
	print("User token received.")
	
	print("Checking user token validity")
	__check_token(__user_token)



func __refresh_token() -> void:
	pass


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
	var body = __parse_body(response)
	
	if body["expires_in"] < 3600:
		print("Token expiring soon. Requesting new token.")
		match token:
			__app_token:
				__get_app_token()
			__user_token:
				__get_user_token()
	else:
		print("Token valid!")
	


func __parse_body(response) -> Dictionary:
	var body = response[3].get_string_from_utf8()
	body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
	body = JSON.parse(body).result
	return body


func __check_tokens() -> void:
	print("Checking app token validity")
	__check_token(__app_token)
	
	print("Checking user token validity")
	__check_token(__user_token)
