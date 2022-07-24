extends HBoxContainer
class_name Status


# Enums

enum { SUCCESS = 0, WARN, ERROR, CHECKING, }

# Public variables

export(int, "Success", "Warn", "Error", "Checking") var state: int setget __state_set, __state_get
export(String) var text: String setget __text_set, __text_get


# Private variables

onready var __icons: Array = [
	$icon_success,
	$icon_warn,
	$icon_error,
	$icon_checking
]
onready var __label: Label = $label


# Lifecycle methods

func _ready() -> void:
	self.state = self.CHECKING
	self.text = text


# Private methods

func __state_get() -> int:
	return state


func __state_set(value: int) -> void:
	state = value

	if __icons != null:
		for index in __icons.size():
			__icons[index].visible = (index == value)
			if value == self.CHECKING:
				$AnimationPlayer.play("checking")
			else:
				$AnimationPlayer.stop()


func __text_get() -> String:
	return text


func __text_set(value: String) -> void:
	text = value

	if __label != null:
		__label.text = value
