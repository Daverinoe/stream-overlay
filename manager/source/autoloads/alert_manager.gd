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
const __HMAC_PREFIX : String = "sha256="
const __TWITCH_MESSAGE_ID : String = 'Twitch-Eventsub-Message-Id'
const __TWITCH_MESSAGE_TIMESTAMP : String = 'Twitch-Eventsub-Message-Timestamp'
const __TWITCH_MESSAGE_SIGNATURE : String = 'Twitch-Eventsub-Message-Signature'

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
var __enet_server : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
var __enet_listening : int = false

################################################
################### ONREADY ####################
################################################

################################################
################## VIRTUALS ####################
################################################

func _ready() -> void:
	Auth.connect("user_id_found", self, "__subscribe_to_events")
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

func _init() -> void:
	__enet_server.connect("peer_connected", self, "__overlay_connection", [true])
	__enet_server.connect("peer_disconnected", self, "__overlay_connection", [false])


func __start_server(port: int = 3080) -> void:
	Console.log("Starting REST server...")
	__server = HTTPServer.new()
	
	__server.endpoint(HTTPServer.Method.GET, "/auth", funcref(self, "__handle_auth"))
	__server.endpoint(HTTPServer.Method.POST, __endpoint_name, funcref(self, "__handle_event"))
	
	__server.listen(port)
	Console.log("REST server is listening on %s with endpoint %s: %s" % [port, __endpoint_name, __server.is_listening()] )
	
	Console.log("Starting Enet server on port 8000...")
		
	__enet_listening = __enet_server.create_server(8000)
	
	get_tree().network_peer = __enet_server
	
	if __enet_listening == OK:
		Console.log("Server created! Listening on 8000...")


func __process_connections() -> void:
	if __server != null:
		__server.process_connection()


func __subscribe_to_events() -> void:
	var subHelper : SubHelper = SubHelper.new()
	var subs_to_sub := subHelper.get_basic_subs()
	
	var headers = [
		"Authorization: Bearer %s" % Auth.__app_token,
		"Client-Id: %s" % OS.get_environment("TWITCH_CLIENT_ID"),
		"Content-Type: application/json",
		]
	
	for sub in subs_to_sub:
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

		Console.log("Requesting subscription to %s" % sub)
		
		var response = yield(http_request, "request_completed")
		
		var response_body = response[3].get_string_from_utf8()
		response_body[-1] = "" # Remove unknown character at end of string -> maybe a weirdly parsed \n?
		response_body = JSON.parse(body).result
		var func_redo : FuncRef = funcref(self, "__subscribe_to_events")
		
		Auth.check_for_401(response, func_redo)
		
		if response[1] == 409:
			Console.log("Subscription to %s already exists!" % sub)


func __handle_event(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	
	# Eventually do this, maybe. Ngrok random endpoints are pretty secure through obscurity.
	
#	var signature : bool = __calc_signature(request, Auth.check_string)
#
#	if !signature:
#		Console.log("Invalid signature on request!")
#		pass
	
	var request_body : Dictionary = JSON.parse(request.body()).result
	
	if request_body.has("challenge"):
		Console.log("Responding to challenge for %s" % request_body.subscription.type)
		
		response.data(request_body.challenge)
		
		Console.log("Subscribed to: %s" % request_body.subscription.type)
	else:
		Console.log("Request received! Request type: %s" % request_body.subscription.type)
		Console.log("Sending request to overlay...")
		rpc("handle_alert", request_body)


func __handle_auth(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	Auth.emit_signal("auth_request", request.params())


func restart() -> void:
	pass


func __overlay_connection(id: int, connected : bool) -> void:
	Console.log("Overlay connection received!")
	if !connected:
		Console.log("Overlay connection failed.")
		self.emit_signal("overlay_found", Status.ERROR)
		return
	
	Console.log("Overlay connection success.")
	self.emit_signal("overlay_found", Status.SUCCESS)


remote func handle_alert(payload) -> void:
	emit_signal("alert", payload)
	print(payload)
