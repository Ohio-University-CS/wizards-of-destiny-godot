extends Control

@onready var back_button : Button = $"Buttons/Back Arrow"
@onready var level_select_button : Button = $"Buttons/Level 5"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Level Select/level_4.tscn")

#func _level_select_button_pressed():
#	get_tree().change_scene_to_file("")
