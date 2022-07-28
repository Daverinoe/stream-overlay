extends Node

################################################
################### SIGNALS ####################
################################################

################################################
#################### ENUMS #####################
################################################

################################################
################## CONSTANTS ###################
################################################

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

func __start_server(port: int = 3080) -> void:
	Console.log("Starting REST server...")
	__server = HTTPServer.new()
	
	__server.endpoint(HTTPServer.Method.GET, "/auth", funcref(self, "__handle_auth"))
	__server.endpoint(HTTPServer.Method.POST, __endpoint_name, funcref(self, "__handle_event"))
	
	__server.listen(port)
	Console.log("REST server is listening on %s with endpoint %s: %s" % [port, __endpoint_name, __server.is_listening()] )
	
	Console.log("Starting websocket alert service...")
	
	__websocket_server = WebSocketServer.new()
	
	__websocket_server.listen(3081, PoolStringArray(), true)


func __process_connections() -> void:
	if __server == null:
		return
	
	__server.process_connection()


func __subscribe_to_events() -> void:
	pass

func __handle_event(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	Console.log(request)

func __handle_auth(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	Auth.emit_signal("auth_granted", request.params())

func restart() -> void:
	pass
