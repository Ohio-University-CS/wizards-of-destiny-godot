# UI Manager
extends Node

func show_card_choice(choice_texts: Array[String], callback: Callable):
	# Instantiates CardChoice, sets up texts, connects signal, and adds to UI
	var card_choice_scene = preload("res://cards/card_choice.tscn")
	var card_choice = card_choice_scene.instantiate()
	card_choice.setup(choice_texts)
	card_choice.choice_made.connect(callback)
	get_tree().current_scene.add_child(card_choice)
