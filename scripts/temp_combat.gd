extends Node2D

@onready var player : Player = $Player
@onready var deck : CombatDeck = $CombatDeck

func _ready():
	var class_data = load("res://cards/data/magician.tres")
	player.setup_from_class(class_data)

	deck.setup_from_class(class_data)

	print("Drawing 5 cards...")
	for i in range(5):
		var card = deck.draw_card()
		if card:
			print(card.data.card_name)
