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
	print("Starting server...")
	__server = HTTPServer.new()
	
	__server.endpoint(HTTPServer.Method.POST, "/auth", funcref(self, "__handle_auth"))
	__server.endpoint(HTTPServer.Method.POST, __endpoint_name, funcref(self, "__handle_event"))
	
	__server.listen(port)
	print("Server is listening on %s with endpoint %s: %s" % [port, __endpoint_name, __server.is_listening()] )
	


func __process_connections() -> void:
	if __server == null:
		return
	
	__server.process_connection()


func __subscribe_to_events() -> void:
	pass

func __handle_event(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	print(request)

func __handle_auth(request: HTTPServer.Request, response: HTTPServer.Response) -> void:
	print(request)

func restart() -> void:
	pass
