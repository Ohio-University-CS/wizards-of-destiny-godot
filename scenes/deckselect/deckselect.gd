extends Control

# Button node
@onready var judgement_button : Button = $Buttons/Judgement

func _ready():
	# Connect the button press
	judgement_button.pressed.connect(_on_judgement_pressed)

# Function called when the button is pressed
func _on_judgement_pressed():
	print("Judgement deck selected")
	get_tree().change_scene_to_file("res://scenes/deckselect/deckselect_judgement.tscn")
