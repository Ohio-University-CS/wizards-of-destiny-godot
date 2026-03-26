# Emperor
extends Control

# Button nodes
@onready var back_button : Button = $Buttons/Back
@onready var forward_button : Button = $Buttons/Forward
@onready var level_select_button : Button = $Buttons/"Level Select"

func _ready():
	# Connect button presses
	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if not forward_button.pressed.is_connected(_on_forward_pressed):
		forward_button.pressed.connect(_on_forward_pressed)
		
	if not level_select_button.pressed.is_connected(_on_level_select_pressed):
		level_select_button.pressed.connect(_on_level_select_pressed)

# Go back to the first deck select screen
func _on_back_pressed():
	print("Back pressed")
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_tower.tscn")

# Go forward to the next deck select screen
func _on_forward_pressed():
	print("Forward pressed")
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_hangedman.tscn")
	
# Go to arena (level select)
func _on_level_select_pressed():
	print("Level Select pressed")
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
