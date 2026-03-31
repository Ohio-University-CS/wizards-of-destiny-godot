# Card Choice
extends Control

signal choice_made(index: int)

@onready var button1 : Button = $VBoxContainer/Choice1
@onready var button2 : Button = $VBoxContainer/Choice2

var choice_texts: Array[String] = []

func _ready():
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	_update_buttons()

func setup(texts: Array[String]):
	choice_texts = texts
	if is_inside_tree():
		_update_buttons()

func _update_buttons():
	if choice_texts.size() >= 2:
		button1.text = choice_texts[0]
		button2.text = choice_texts[1]

func _on_button1_pressed():
	emit_signal("choice_made", 0)
	queue_free()

func _on_button2_pressed():
	emit_signal("choice_made", 1)
	queue_free()
