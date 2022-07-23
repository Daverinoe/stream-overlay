extends Tabs

var alert_server : AlertManager = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_start_server_button_pressed() -> void:
	alert_server = AlertManager.new()
	self.call_deferred("add_child", alert_server)
