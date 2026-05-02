extends Control

@onready var forward_button : Button = $"Buttons/Forward Arrow"
@onready var back_button : Button = $"Buttons/Back Arrow"
@onready var level_select_button : Button = $"Buttons/Level 3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	forward_button.pressed.connect(_on_forward_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_forward_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Level Select/level_4.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Level Select/level_2.tscn")

#func _level_select_button_pressed():
#	get_tree().change_scene_to_file("")
