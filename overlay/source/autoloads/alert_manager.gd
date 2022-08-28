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

var __enet_client : NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()

################################################
################### ONREADY ####################
################################################

################################################
################## VIRTUALS ####################
################################################

func _init() -> void:
	__enet_client.connect("connection_succeeded", self, "__connected")


func _ready() -> void:
	print("Creating client...")
	__enet_client.create_client("localhost", 8000)
	get_tree().network_peer = __enet_client
	

################################################
############### PUBLIC METHODS #################
################################################

remote func handle_alert(payload) -> void:
	
	var type = payload.subscription.type
	var subtype
	var user_avatar
	var name
	
	match type:
		"channel.follow":
			subtype = "follow"
			name = payload.event.user_name
		"channel.raid":
			subtype = "raid"
			name = payload.event.from_broadcaster_user_name
			user_avatar = payload.user_texture
	
	
	Event.emit_signal("alert", {"name": name, "type": subtype, "user_avatar": user_avatar})


################################################
############## PRIVATE METHODS #################
################################################

func __connected() -> void:
	print("Connected!")
