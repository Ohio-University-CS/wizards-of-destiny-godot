
# Seed Input
extends Control

@onready var line_edit : LineEdit = $VBoxContainer/LineEdit
@onready var random_button : Button = $VBoxContainer/HBoxContainer/RandomSeed
@onready var proceed_button : Button = $VBoxContainer/HBoxContainer/Proceed

func _ready():
	proceed_button.pressed.connect(_on_proceed_pressed)
	random_button.pressed.connect(_on_random_pressed)

func _on_proceed_pressed():
	var seed_text = line_edit.text.strip_edges()
	var seed : int
	if seed_text == "":
		seed = randi() # Use a random seed if left blank
	else:
		# Try to parse as int, fallback to hash if not numeric
		seed = int(seed_text) if seed_text.is_valid_int() else seed_text.hash()
	# Start the run with the chosen seed
	RunManager.start_new_run(null, seed)
	# Optionally, print or store the seed for debugging
	print("Seed used:", seed)
	# Change to item selection scene (update path as needed)
	get_tree().change_scene_to_file("res://items/Start_Item_Select.tscn")

func _on_random_pressed():
	var random_seed = randi()
	line_edit.text = str(random_seed)
