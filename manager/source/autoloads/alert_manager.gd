extends Node

################################################
################### SIGNALS ####################
################################################

signal overlay_found(status)

################################################
#################### ENUMS #####################
################################################

################################################
################## CONSTANTS ###################
################################################
const __TWITCH_SUBSCRIPTION_URI : String = "https://api.twitch.tv/helix/eventsub/subscriptions"

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
var __websocket_server : WebSocketServer = null

################################################
################### ONREADY ####################
################################################

################################################
################## VIRTUALS ####################
################################################

func _ready() -> void:
#	Auth.connect("user_id_found", self, "__subscribe_to_events")
	pass


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

func __start_server(port: int = 443) -> void:
	Console.log("Starting REST server...")
	__server = HTTPServer.new()
	
	__server.endpoint(HTTPServer.Method.GET, "/auth", funcref(self, "__handle_auth"))
	__server.endpoint(HTTPServer.Method.POST, __endpoint_name, funcref(self, "__handle_event"))
	
	__server.listen(port)
	Console.log("REST server is listening on %s with endpoint %s: %s" % [port, __endpoint_name, __server.is_listening()] )
	
	Console.log("Starting websocket alert service...")
	
	__websocket_server = WebSocketServer.new()
	
	__websocket_server.listen(3080, PoolStringArray(), true)
	__websocket_server.connect("client_connected", self, "__overlay_connection", [true])
	__websocket_server.connect("client_disconnected", self, "__overlay_connection", [false])
	
	__subscribe_to_events()


func __process_connections() -> void:
	if __server == null:
		return
	
	__server.process_connection()
#	__websocket_server.poll()


func __subscribe_to_events() -> void:
	var subHelper : SubHelper = SubHelper.new()
	var subs_to_sub := subHelper.get_basic_subs()
	
	var headers = [
		"Authorization: Bearer %s" % Auth.__app_token,
		"Client-Id: %s" % OS.get_environment("TWITCH_CLIENT_ID"),
		"Content-Type: application/json",
		]
	
	for sub in [subs_to_sub[0]]:
		var http_request : HTTPRequest = HTTPRequest.new()
		self.add_child(http_request)
		var key : String = ""
		var value : String = ""
		match sub:
			"channel.raid":
				key = "to_broadcaster_user_id"
				value = Auth.user_id
			_:
				key = "broadcaster_user_id"
				value = Auth.user_id
		
		var body = JSON.print({
			"type": sub,
			"version": "1",
			"condition":{
				key: value
			},
			"transport":{
				"method": "webhook",
				"callback": Auth.ngrok_endpoint + __endpoint_name,
				"secret": Auth.check_string
			}
		})

		var post = HTTPClient.METHOD_POST
		
		http_request.request(__TWITCH_SUBSCRIPTION_URI, headers, true, post, body)

		Console.log("Requesting subscription...")
		
		var response = yield(http_request, "request_completed")
		
		var response_body = response[3].get_string_from_utf8()
		response_body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
		response_body = JSON.parse(body).result
		var func_redo : FuncRef = funcref(self, "__subscribe_to_events")
		Auth.check_status(response, func_redo)
		
		Console.log("Subscribed to: %s" % response_body.type)


func __handle_event(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	Console.log(request)


func __handle_auth(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	Auth.emit_signal("auth_request", request.params())


func restart() -> void:
	pass


func __overlay_connection(connected : bool) -> void:
	if !connected:
		self.emit_signal("overlay_found", false)
		return
	
	self.emit_signal("overlay_found", true)
