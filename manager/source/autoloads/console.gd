extends Node

onready var __console_ref : RichTextLabel = get_tree().root.get_node("main/container_content/main_divider/console_back/console_margins/console")

func _ready() -> void:
	self.log("Welcome to Stream Manager!")

func log(log_string) -> void:
	var time = OS.get_datetime()
	var timestamp = "[%s:%s:%s]: " % [time["hour"], time["minute"], time["second"]]
	__console_ref.text += ("\n%s" % timestamp) + (log_string as String)
