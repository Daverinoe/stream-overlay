extends Control

# Const variables

const FOLLOW_ALERT = preload("res://source/alerts/follow_alert.tscn")
const RAID_ALERT = preload("res://source/alerts/raid_alert.tscn")


# Private variables

var __alerts: Array = []
var __alert_playing: bool = false


# Lifecycle methods

func _ready() -> void:
	Event.connect("alert", self, "__handle_alert")
	get_tree().get_root().set_transparent_background(true)

	var timer: Timer = Timer.new()
	timer.one_shot = true
	add_child(timer)

	timer.start(2.0)
	yield(timer, "timeout")

	__alert("incompetent_ian", "subscribe")
	timer.start(0.5)
	yield(timer, "timeout")

	__alert("deschainxiv", "follow")
	timer.start(1.5)
	yield(timer, "timeout")

	__alert("Liioni", "subscribe")
	timer.start(0.5)
	yield(timer, "timeout")

	__alert("cavedens", "subscribe")
	timer.start(0.5)
	yield(timer, "timeout")

	__alert("TheYagich", "unfollow")
	__alert("Lumikkode", "loves")

	remove_child(timer)


func _process(delta) -> void:
	__check_alerts()


# Private methods

func __alert(user: String, type: String, user_avatar = null) -> void:
	var instance
	match type:
		"follow":
			instance = FOLLOW_ALERT.instance()
		"raid":
			instance = RAID_ALERT.instance()
			instance.raider_image = user_avatar
		_:
			pass
	
	if instance != null:

		instance.user = user

		__alerts.append(instance)

	else:
		pass


func __handle_alert(payload: Dictionary) -> void:
	
	var name = payload.name
	var type = payload.type
	var raider_avatar = payload.user_avatar
	
	__alert(name, type, raider_avatar)


func __check_alerts() -> void:
	if __alerts.size() > 0:
		if !__alert_playing:
			
			__alert_playing = true
			
			add_child(__alerts[0])
			
			yield(__alerts[0], "complete")
			
			remove_child(__alerts[0])
			
			__alerts.pop_front()
			
			__alert_playing = false
		else:
			pass
	else:
		pass
