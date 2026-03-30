# Card Choice
extends Control

var effect : ChoiceEffect

@onready var button1 : Button = $VBoxContainer/Choice1
@onready var button2 : Button = $VBoxContainer/Choice2


func _ready():
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)

func setup(choice_effect: ChoiceEffect):
	effect = choice_effect
	
	button1.text = effect.choice_texts[0]
	button2.text = effect.choice_texts[1]

func _on_button1_pressed():
	effect.resolve_choice(0)
	queue_free()

func _on_button2_pressed():
	effect.resolve_choice(1)
	queue_free()
