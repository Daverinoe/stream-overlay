extends Node
class_name AlertManager

################################################
################### SIGNALS ####################
################################################

signal __ngrok_found

################################################
#################### ENUMS #####################
################################################

enum {
	CHANNEL_UPDATE = 0,
	CHANNEL_FOLLOW,
	CHANNEL_SUBSCRIBE,
	CHANNEL_SUBSCRIPTION_END,
	CHANNEL_SUBSCRIPTION_GIFT,
	CHANNEL_SUSCRIPTION_MESSAGE,
	CHANNEL_CHEER,
	CHANNEL_RAID,
	CHANNEL_BAN,
	CHANNEL_UNBAN,
	CHANNEL_MODERATOR_ADD,
	CHANEL_MODERATOR_REMOVED,
	CHANNEL_POINTS_CUSTOM_REWARD_ADD,
	CHANNEL_POINTS_CUSTOM_REWARD_UPDATE,
	CHANNEL_POINTS_CUSTOM_REWARD_REMOVE,
	CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD,
	CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_UPDATE,
	CHANNEL_POLL_BEGIN,
	CHANNEL_POLL_PROGRESS,
	CHANNEL_POLL_END,
	CHANNEL_PREDICTION_BEGIN,
	CHANNEL_PREDICTION_PROGRESS,
	CHANNEL_PREDICTION_LOCK,
	CHANNEL_PREDICTION_END,
	DROP_ENTITLEMENT_GRANT,
	EXTENSION_BITS_TRANSACTION_CREATE,
	GOAL_BEGIN,
	GOAL_PROGRESS,
	GOAL_END,
	HYPE_TRAIN_BEGIN,
	HYPE_TRAIN_PROGRESS,
	HYPE_TRAIN_END,
	STREAM_ONLINE,
	STREAM_OGGLINE,
	USER_AUTHORIZATION_GRANT,
	USER_AUTHORIZATION_REVOKE,
	USER_UPDATE,
}


################################################
################## CONSTANTS ###################
################################################

const __ngrok_url = "http://127.0.0.1:4040/api/tunnels"

################################################
################### EXPORTS ####################
################################################

################################################
################### PUBLIC #####################
################################################

################################################
################### PRIVATE ####################
################################################

var __server : HTTPServer = null
var __endpoint_name : String = "/callback"
var __callback_endpoint : String = ""
var __ngrok_endpoint : String = ""
var __http_response = null

# For GET/POST requests regarding ngrok, authcodes, etc
var __http_request : HTTPRequest = null

################################################
################### ONREADY ####################
################################################

func _process(delta: float) -> void:
	if __server == null:
		__start_server()
	
	__process_connections()

################################################
############### PUBLIC METHODS #################
################################################

################################################
############## PRIVATE METHODS #################
################################################

func _ready() -> void:
	__http_request = HTTPRequest.new()
	self.add_child(__http_request)

func __start_server(port: int = 3080) -> void:
	print("Starting server...")
	__server = HTTPServer.new()
	
	__server.endpoint(HTTPServer.Method.POST, __endpoint_name, funcref(self, "__handle_event"))
	
	__get_ngrok_endpoint()
	yield(self, "__ngrok_found")
	__callback_endpoint = __ngrok_endpoint + __endpoint_name
	print("Alert server callback endpoint: %s" % __callback_endpoint)
	__subscribe_to_events(__callback_endpoint)


func __process_connections() -> void:
#	if __server == null:
#		__start_server()
	
	__server.take_connection()


func __get_ngrok_endpoint() -> void:
	
	var custom_header : PoolStringArray = ["Content-Type: application/json"]
	var error = __http_request.request(__ngrok_url, custom_header)
	
	if error != OK:
		push_error("An error occurred when probing ngrok.")
	
	print("ngrok OK!")
	
	var response = yield(__http_request, "request_completed")
	
	__parse_response(response[0], response[1], response[2], response[3])
	
	var url = __http_response["tunnels"][0].public_url
	__ngrok_endpoint = url.replace("http://", "https://")
	print("ngrok endpoint: %s" % __ngrok_endpoint)
	self.emit_signal("__ngrok_found")


func __subscribe_to_events(callback_endpoint : String) -> void:
	pass


func __parse_response(result, response_code, headers, body):
	__http_response = parse_json(body.get_string_from_utf8())
