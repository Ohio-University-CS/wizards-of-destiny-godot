class_name DrawCardsEffect extends Effect

@export var amount : int = 1

func apply(_source, _target, combat):

	for i in range(amount):

		if combat.hand_cards.size() >= combat.deck.max_hand_size:
			return

		var card = combat.deck.draw_card()

		if card:
			combat.spawn_card(card)
