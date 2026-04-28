extends Control

@onready var forward_button : Button = $"Buttons/Forward Arrow"
@onready var back_button : Button = $"Buttons/Back Arrow"
@onready var level_select_button : Button = $"Buttons/Level 2"
@onready var animatedsprite = $"Animation/AnimatedSprite2D"
@onready var Buttons = $"Buttons"

func _ready() -> void:
	animatedsprite.speed_scale = 2.0  # 2x faster
	await _animation_open()
	
	forward_button.pressed.connect(_on_forward_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	level_select_button.pressed.connect(_level_select_button_pressed)

func _process(_delta: float) -> void:
	pass

func get_forward_scene_path() -> String:
	return "res://scenes/Level Select/level_3.tscn"

func get_back_scene_path() -> String:
	return "res://scenes/Level Select/level_1.tscn"

func has_valid_forward_button() -> bool:
	return forward_button != null

func has_valid_back_button() -> bool:
	return back_button != null

func _on_forward_button_pressed():
	await _animation_close()
	get_tree().change_scene_to_file(get_forward_scene_path())

func _on_back_button_pressed():
	await _animation_close()
	get_tree().change_scene_to_file(get_back_scene_path())

func _level_select_button_pressed():
	await _animation_close()
	if(GameStateManager.game_loaded):
		FlowManager.go_to_combat()
	else:
		get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_magician.tscn")

func _animation_open():
	Buttons.hide()
	animatedsprite.show()
	animatedsprite.play("Open")
	await animatedsprite.animation_finished
	animatedsprite.hide()
	Buttons.show()

func _animation_close():
	Buttons.hide()
	animatedsprite.show()
	animatedsprite.play("Close")
	await animatedsprite.animation_finished
	animatedsprite.hide()
