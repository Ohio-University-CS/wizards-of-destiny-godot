extends Control

@onready var AnimatedSprite: AnimatedSprite2D = $Scroll_Animation/AnimatedSprite2D
@onready var button = $Buttons
@onready var graphics_button = $"Buttons/Graphics Button"
@onready var sound_button = $"Buttons/Sound Button"
@onready var control_button = $"Buttons/Control Button"
@onready var exit_button : Button = $Buttons/Exit
@onready var unrolled_scroll = $Unrolled_Scroll
@onready var gso = $"gsettingsoptions"
@onready var fullscreen_button = $"gsettingsoptions/FullScreen button"
@onready var fullscreen_on = $"gsettingsoptions/Fullscreen label/Fullscreen ON"
@onready var fullscreen_off = $"gsettingsoptions/Fullscreen label/Fullscreen OFF"
@onready var soundsettings = $"soundsettingoptions"
@onready var main_slider = $"soundsettingoptions/mvs"
@onready var music_slider = $"soundsettingoptions/musicvs"
@onready var sfx_slider = $"soundsettingoptions/sfvs"

var last_opened: String = "N/A"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#visibility
	AnimatedSprite.hide()
	unrolled_scroll.hide()
	_gso_off()
	_sso_off()
	#settings
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	#buttons
	graphics_button.pressed.connect(_on_graphics_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	control_button.pressed.connect(_on_control_pressed)
	exit_button.pressed.connect(_on_back_pressed)
	if not fullscreen_button.pressed.is_connected(_on_full_screen_button_pressed):
		fullscreen_button.pressed.connect(_on_full_screen_button_pressed)
	#sound
	main_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))


func _on_graphics_pressed():
	if last_opened == "graphics":
		return
	_sso_off()
	if not unrolled_scroll.visible:
		AnimatedSprite.show()
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
		
	else:
		unrolled_scroll.hide()
		AnimatedSprite.play("Close")
		await AnimatedSprite.animation_finished
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
	last_opened = "graphics"
	#
	unrolled_scroll.show()
	fullscreen_button.show()
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_off.hide()
		fullscreen_on.show()
	else:
		fullscreen_on.hide()
		fullscreen_off.show()


func _on_sound_pressed():
	if last_opened == "sound":
		return
	
	_gso_off()
	if not unrolled_scroll.visible:
		AnimatedSprite.show()
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
		unrolled_scroll.show()
	else:
		unrolled_scroll.hide()
		AnimatedSprite.play("Close")
		await AnimatedSprite.animation_finished
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
		unrolled_scroll.show()
	last_opened = "sound"
	soundsettings.show()


func _on_control_pressed():
	if last_opened == "controls":
		return
	_gso_off()
	_sso_off()
	if not unrolled_scroll.visible:
		AnimatedSprite.show()
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
		unrolled_scroll.show()
	else:
		unrolled_scroll.hide()
		AnimatedSprite.play("Close")
		await AnimatedSprite.animation_finished
		AnimatedSprite.play("Open")
		await AnimatedSprite.animation_finished
		unrolled_scroll.show()
	last_opened = "controls"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_full_screen_button_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_on.hide()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_off.show()
	else:
		fullscreen_off.hide()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_on.show()
	# Replace with function body.


func _gso_off() -> void:
	fullscreen_off.hide()
	fullscreen_on.hide()
	fullscreen_button.hide()
	pass


func _sso_off() -> void:
	soundsettings.hide()


func _on_mvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)


func _on_musicvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value)


func _on_sfvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
