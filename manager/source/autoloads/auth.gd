extends Node

################################################
################### SIGNALS ####################
################################################

signal __ngrok_found(status)
signal __token_granted

################################################
################## CONSTANTS ###################
################################################

const __ngrok_url = "http://127.0.0.1:4040/api/tunnels"
const __twitch_token_URI = "https://id.twitch.tv/oauth2/token"
const __twitch_auth_URI = "https://id.twitch.tv/oauth2/authorize?"
const __check_string = "D4ver1noeSchm@ver!noe"

################################################
################### PUBLIC #####################
################################################

var auth_token : String

################################################
################### PRIVATE ####################
################################################

var __endpoint_name : String = "/auth"
var __callback_endpoint : String = ""
var __ngrok_endpoint : String = ""
var __http_response = null
# For GET/POST requests regarding ngrok, authcodes, etc
var __http_request : HTTPRequest = null
var __timeout_timer : Timer = Timer.new()
var __was_cancelled : bool = false


func _ready() -> void:
	__http_request = HTTPRequest.new()
	__timeout_timer.wait_time = 0.5
	__timeout_timer.one_shot = true
	__timeout_timer.connect("timeout", self, "__http_timeout")
	self.add_child(__timeout_timer)
	self.add_child(__http_request)
	
	__get_ngrok_endpoint()
	yield(self, "__ngrok_found")
	__callback_endpoint = __ngrok_endpoint + __endpoint_name
	print("Alert server callback endpoint: %s" % __callback_endpoint)
	if __callback_endpoint != __endpoint_name:
		__request_user_auth()


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
	
	subs.queue_free()
	pass


func __get_ngrok_endpoint() -> void:
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


func __parse_response(result, response_code, headers, body):
	__http_response = parse_json(body.get_string_from_utf8())

func __http_timeout() -> void:
	__http_request.cancel_request()
	__was_cancelled = true
	self.emit_signal("__ngrok_found", Status.ERROR)
