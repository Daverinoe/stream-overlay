extends HBoxContainer

var __status_object_dict : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in self.get_children():
		var type = child.name.replace("status_", "")
		__status_object_dict[type] = child
	
	Auth.connect("__ngrok_found", self, "__change_status", ["ngrok"])


func __change_status(status : bool, type : String) -> void:
	__status_object_dict[type].state = status
