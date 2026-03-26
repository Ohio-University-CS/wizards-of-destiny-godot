# Used to draw another card

class_name DrawCardsEffect extends Effect

@export var amount : int = 1

func apply(_source, _target, combat):
	for i in range(amount):
		var hand_size = 0
		# Directly access hand property on deck if it exists
		if combat.deck.hand != null:
			hand_size = combat.deck.hand.size()
		elif combat.hand_cards != null:
			hand_size = combat.hand_cards.size()
		else:
			print("[DrawCardsEffect] Could not determine hand size!")
		if hand_size >= combat.deck.max_hand_size:
			return

		var card_instance = combat.deck.draw_card()
		if card_instance:
			combat.spawn_card(card_instance)
		else:
			print("[DrawCardsEffect] No card drawn (deck empty?)")
