class_name Alert extends Control


# Signals

signal complete()


# Private constants

const __DURATION: float = 4.0
const __BURN_TIME: float = 1.0

# Public variable

var user: String = "test user"


# Private variable

onready var __label: RichTextLabel = $Viewport/Control/label
onready var __alert_texture: TextureRect = $viewport_texture
onready var __audio_player: AudioStreamPlayer = $alert_sound

var __vertical_tween: Tween = null
var __rng = RandomNumberGenerator.new()


# Lifecycle methods

func _ready() -> void:
	__rng.randomize()
	
	__update_text(false)
	__choose_music()

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = __DURATION
	add_child(timer)

	var audio_tween: Tween = Tween.new()
	add_child(audio_tween)
	
	audio_tween.interpolate_method(
		self,
		"__update_volume",
		0.0,
		1.0,
		__BURN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	audio_tween.start()


	var tween: Tween = Tween.new()
	add_child(tween)

	tween.interpolate_method(
		self,
		"__update_burn",
		1.0,
		0.0,
		__BURN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()
	yield(tween, "tween_completed")

	timer.start()
	yield(timer, "timeout")
	
	audio_tween.interpolate_method(
		self,
		"__update_volume",
		1.0,
		0.0,
		__BURN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	audio_tween.start()
	
	tween.interpolate_method(
		self,
		"__update_burn",
		0.0,
		1.0,
		__BURN_TIME,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()
	yield(tween, "tween_completed")

	remove_child(timer)
	remove_child(audio_tween)
	remove_child(tween)

	emit_signal("complete")


# Public methods

# Private methods

func __update_text(lower: bool) -> void:
	var text: String = "%s\n%s!" % [user, "followed"]

	__label.bbcode_text = "[center]%s[/center]" % text


func __update_burn(burn_amount: float) -> void:
	__alert_texture.material.set_shader_param("dissolve_amount", burn_amount)


func __choose_music() -> void:
	# Pick a random song, at a random time
	var path = "res://source/assets/audio/music/"
	var list_of_songs = FileManager.list_files_in_folder(path)
	var chosen_song = list_of_songs[__rng.randi_range(0, list_of_songs.size() - 1)]
	var song = load(path + chosen_song)
	__audio_player.set_stream(song)
	
	var songLength = __audio_player.stream.get_length()
	var songStart = 0
	if !songLength <= 15:
		songStart = __rng.randf_range(0, songLength - 10)
	
	__audio_player.play(songStart)


func __update_volume(new_volume: float) -> void:
	__audio_player.volume_db = linear2db(new_volume)
