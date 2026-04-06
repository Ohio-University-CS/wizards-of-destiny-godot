# Magician
extends Control

# Button node
@onready var judgement_button : Button = $Buttons/Judgement
@onready var level_select_button : Button = $Buttons/"Level Select"

func _ready():
	# Connect the button press
	if not judgement_button.pressed.is_connected(_on_judgement_pressed):
		judgement_button.pressed.connect(_on_judgement_pressed)
	if not level_select_button.pressed.is_connected(_on_level_select_pressed):
		level_select_button.pressed.connect(_on_level_select_pressed)

# Function called when the button is pressed
func _on_judgement_pressed():
	print("Judgement deck selected")
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_judgement.tscn")
	
# Go to arena (level select)
func _on_level_select_pressed():
	print("Level Select pressed")
	if RunManager.seed_scene:
		get_tree().change_scene_to_file("res://scenes/seed_input/seed_input.tscn")
	else:
		get_tree().change_scene_to_file("res://items/Start_Item_Select.tscn")
