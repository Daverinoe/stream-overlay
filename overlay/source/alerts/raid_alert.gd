extends Node2D

# Signals

signal complete()

onready var __streamer_banner = $streamer_background
onready var __raider_banner = $raider_background
onready var __raider_sprite : Sprite = $raider_background/Sprite
onready var __vs_text = $vs_label
onready var raider_texture : ImageTexture = ImageTexture.new()


var raider_image
var user : String = ""

var __tween : Tween = Tween.new()



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(__tween)
	
	# Set parameters on texture for higher quality
	
	# Reconstruct image from image buffer
	var image = Image.new()
	var image_error = image.load_png_from_buffer(raider_image)
	if image_error != OK:
		print("Error retrieving user avatar!")
	
	raider_texture.create_from_image(image, 1)
	__raider_sprite.texture = raider_texture
	
	yield(__raid_start(), "completed")
	yield(get_tree().create_timer(2.0), "timeout")
	yield(__raid_end(), "completed")
	emit_signal("complete")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func __raid_start() -> void:
	
	__tween.interpolate_property(
		__streamer_banner,
		"rect_position:x",
		-1480,
		-100,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	__tween.interpolate_property(
		__vs_text,
		"rect_position:y",
		1480,
		465,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN,
		0.75
	)
	
	__tween.interpolate_property(
		__raider_banner,
		"rect_position:x",
		2020,
		780,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN,
		1.5
	)
	
	__tween.start()
	yield(__tween, "tween_all_completed")


func __raid_end() -> void:
	
	__tween.interpolate_property(
		__streamer_banner,
		"rect_position:x",
		-100,
		-1480,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	__tween.interpolate_property(
		__vs_text,
		"rect_position:y",
		465,
		-280,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	__tween.interpolate_property(
		__raider_banner,
		"rect_position:x",
		780,
		2020,
		0.75,
		Tween.TRANS_EXPO,
		Tween.EASE_IN
	)
	
	__tween.start()
	yield(__tween, "tween_all_completed")
