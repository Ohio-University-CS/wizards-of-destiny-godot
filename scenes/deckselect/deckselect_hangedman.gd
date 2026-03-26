# Emperor
extends Control

# Button nodes
@onready var back_button : Button = $Buttons/Back

func _ready():
	# Connect button presses
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


# Go back to the first deck select screen
func _on_back_pressed():
	print("Back pressed")
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_death.tscn")

# Go forward to the next deck select screen
