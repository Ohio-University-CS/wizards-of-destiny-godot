extends Control

@onready var forward_button : Button = $"Buttons/Forward Arrow"
@onready var back_button : Button = $"Buttons/Back Arrow"
@onready var level_select_button : Button = $"Buttons/Level 2"

func _ready() -> void:
	forward_button.pressed.connect(_on_forward_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

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
	get_tree().change_scene_to_file(get_forward_scene_path())

func _on_back_button_pressed():
	get_tree().change_scene_to_file(get_back_scene_path())
