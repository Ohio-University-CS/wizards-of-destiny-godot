extends Control

@onready var forward_button : Button = $"Buttons/Forward Arrow"
@onready var level_select_button : Button = $"Buttons/Level 1"
@onready var exit_button : Button = $Buttons/Exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	forward_button.pressed.connect(_on_forward_button_pressed)
	level_select_button.pressed.connect(_level_select_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_forward_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Level Select/level_2.tscn")

func _level_select_button_pressed():
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_magician.tscn")
	
func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
