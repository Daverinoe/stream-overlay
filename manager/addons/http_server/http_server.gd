class_name HTTPServer extends TCP_Server


# Public constants

const Method = preload("res://addons/http_server/method.gd")
const Request = preload("res://addons/http_server/request.gd")
const Response = preload("res://addons/http_server/response.gd")
const Status = preload("res://addons/http_server/status.gd")


# Private variables

var __endpoints: Dictionary = {
	# key: [Int, String], array with 0 index representing method, 1 index representing endpoint
	# value: FuncRef, reference to function to call
}
var __fallback: FuncRef = null
var __server: TCP_Server = null


# Public methods

func endpoint(type: int, endpoint: String, function: FuncRef) -> void:
	var endpoint_hash: Array = [type, endpoint]
	if endpoint_hash in __endpoints:
		print(
			"[ERR] Endpoint already defined type: %s, endpoint: %s" % [
				Method.type_to_identifier(type),
				endpoint,
			]
		)
		return

	__endpoints[endpoint_hash] = function


func fallback(function: FuncRef) -> void:
	__fallback = function


func process_connection() -> void:
	if !is_listening():
		print(
			"[ERR] Server is not listening, please initialize and listen before calling `take_connection`"
		)
		return

	var connection: StreamPeerTCP = self.take_connection()

	if connection:
		__process_connection(connection)


# Private methods

func __process_connection(connection: StreamPeerTCP) -> void:
	var content: PoolByteArray = PoolByteArray([])

	while true:
		var bytes = connection.get_available_bytes()
		if bytes == 0:
			break

		var data = connection.get_partial_data(bytes)
		content.append_array(data[1])

	if content.empty():
		return

	var content_string: String = content.get_string_from_utf8()
	var content_parts: Array = content_string.split("\r\n")

	if content_parts.empty():
		connection.put_data(__response_from_status(Status.BAD_REQUEST).to_utf8())
		return

	var request_line = content_parts[0]
	var request_line_parts = request_line.split(" ")

	var method: String = request_line_parts[0]
	var url: PoolStringArray = request_line_parts[1].split("?")
	var endpoint: String = url[0]
	var params_pool: PoolStringArray = (url[1] as String).percent_decode().split("&")
	var params: Dictionary = {}
	
	for line in params_pool:
		var temp = line.split("=")
		if "+" in (temp[1] as String):
			params[temp[0]] = temp[1].split("+")
		else:
			params[temp[0]] = temp[1]
	
	var headers: Dictionary = {}
	var header_index: int = content_parts.find("")

	if header_index == -1:
		print(
			"[ERR] Error parsing request data: %s" % [String(content)]
		)
		connection.put_data(__response_from_status(Status.BAD_REQUEST).to_utf8())
		return

	for i in range(1, header_index):
		var header_parts: Array = content_parts[i].split(":", true, 1)
		var header = header_parts[0].strip_edges().to_lower()
		var value = header_parts[1].strip_edges()

		headers[header] = value

	var body: String = ""
	if header_index != content_parts.size() - 1:
		var body_parts: Array = content_parts.slice(header_index + 1, content_parts.size())
		body = PoolStringArray(body_parts).join("\r\n")

	var response: Response = __process_request(method, endpoint, params, headers, body)
	connection.put_data(response.to_utf8())
	if response.__file != null:
		connection.put_data("\r\n".to_utf8())

		var stream: Response.FileStream = response.to_stream()

		while !stream.end_of_file():
			var data: PoolByteArray = stream.chunk()
			connection.put_data(data)

	connection.disconnect_from_host()


func __process_request(method: String, endpoint: String, params: Dictionary, headers: Dictionary, body: String) -> Response:
	var type: int = Method.description_to_type(method)

	var request: Request = Request.new(
		type,
		endpoint,
		params,
		headers,
		body
	)

	var endpoint_func: FuncRef = null
	var endpoint_hash: Array = [type, endpoint]
	if !__endpoints.has(endpoint_hash):
		print(
			"[WRN] Recieved request for unknown endpoint, method: %s, endpoint: %s" % [method, endpoint]
		)
		if __fallback:
			endpoint_func = __fallback
		else:
			return __response_from_status(Status.NOT_FOUND)
	else:
		endpoint_func = __endpoints[endpoint_hash]

	var response: Response = Response.new()

	if !endpoint_func.is_valid():
		print(
			"[ERR] FuncRef for endpoint not valid, method: %s, endpoint: %s" % [method, endpoint]
		)
	else:
		print(
			"[INF] Recieved request method: %s, endpoint: %s" % [method, endpoint]
		)
		endpoint_func.call_func(request, response)

	return response


func __response_from_status(code: int) -> Response:
	var response: Response = Response.new()
	response.status(code)

	return response
