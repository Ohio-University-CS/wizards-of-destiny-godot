extends Node2D

@onready var player : Player = $Player
@onready var deck : CombatDeck = $CombatDeck

@export var card_scene : PackedScene
@export var class_data : ClassData


func _ready():
	player.setup_from_class(class_data)
	deck.setup_from_class(class_data)

	draw_hand()

func draw_hand():
	for i in range(5):
		var card_instance = deck.draw_card()
		if card_instance:
			spawn_card(card_instance)

func spawn_card(instance : CardInstance):
	var card = card_scene.instantiate()
	add_child(card)

	card.setup(instance)

	card.position = Vector2(200 + deck.hand.size() * 180, 500)

	card.card_clicked.connect(func(): play_card(card))


func play_card(card_scene):
	var instance = card_scene.card_instance

	var dummy_enemy = player  # temporary target for testing

	if instance.play(dummy_enemy, player):
		if instance.exhausted:
			deck.exhaust_card(instance)
		else:
			deck.discard_card(instance)

		card_scene.queue_free()
