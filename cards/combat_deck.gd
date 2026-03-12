extends Node
class_name CombatDeck

var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []

@export var max_hand_size := 5

@export var starting_deck: Array[CardData]
@export var basic_attack: CardData = preload("res://cards/data/basic_attack.tres")

func setup_from_class(class_data: ClassData):
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	hand.clear()

	# Guarantee opening hand always includes Basic Attack.
	if basic_attack != null and max_hand_size > 0:
		hand.append(CardInstance.new(basic_attack))

	for card_data in class_data.starting_deck:
		draw_pile.append(CardInstance.new(card_data))

	shuffle_draw()

func shuffle_draw():
	draw_pile.shuffle()

func draw_card():
	if draw_pile.is_empty():
		reshuffle()

	if draw_pile.is_empty():
		return null

	if hand.size() >= max_hand_size:
		return null

	var card = draw_pile.pop_back()
	hand.append(card)
	return card

func reshuffle():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_draw()

func discard_card(card: CardInstance):
	hand.erase(card)
	discard_pile.append(card)

func exhaust_card(card: CardInstance):
	hand.erase(card)
	exhaust_pile.append(card)
