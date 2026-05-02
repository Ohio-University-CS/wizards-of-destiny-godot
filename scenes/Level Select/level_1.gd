extends Control

@onready var forward_button : Button = $"Buttons/Forward Arrow"
@onready var level_select_button : Button = $"Buttons/Level 1"
@onready var exit_button : Button = $"Buttons/Home Arrow"
@onready var animatedsprite = $"Animation/AnimatedSprite2D"
@onready var Buttons = $"Buttons"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animatedsprite.speed_scale = 2.0  # 2x faster
	await _animation_open()
	forward_button.pressed.connect(_on_forward_button_pressed)
	level_select_button.pressed.connect(_level_select_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_forward_button_pressed():
	await _animation_close()
	get_tree().change_scene_to_file("res://scenes/Level Select/level_2.tscn")

func _level_select_button_pressed():
	await _animation_close()
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_magician.tscn")
	
func _on_exit_pressed():
	await _animation_close()
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")

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
