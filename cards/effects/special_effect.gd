class_name SpecialEffect extends Effect

enum CardName {
	ABJURATION,
	FIRE_BOLT,
	SHOCKING_GRASP
}

@export var card_name : CardName


func apply(source, target, combat):
	if card_name == CardName.ABJURATION:
		if source and source.has_method("add_strike_damage") and source.has_method("get_block"):
			var block_damage = source.get_block()
			source.add_strike_damage(block_damage, false)
	
	if card_name == CardName.FIRE_BOLT:
		if target and target.has_method("get_burn"):
			if source and source.has_method("add_strike_status"):
				if target.get_burn() > 0:
					source.add_strike_status("burn", 2)
				else:
					source.add_strike_status("burn", 1)
	
	if card_name == CardName.SHOCKING_GRASP:
		if target and target.has_method("get_shock"):
			if source and source.has_method("add_strike_status"):
				source.add_strike_status("shock", 1)
				if target.get_shock() > 0:
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
