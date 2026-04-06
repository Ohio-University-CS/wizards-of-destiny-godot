class_name SpecialEffect extends Effect

enum CardName {
	ABJURATION,
	DIVINE_INCANTATION,
	DUPLICATE,
	FIRE_BOLT,
	GRAND_FINALE,
	LAY_ON_HANDS,
	LIGHTNING_STRIKE,
	POTENTIAL_DESTRUCTION,
	SHOCKING_GRASP,
	STATIC_FIELD,
	THUNDERWAVE
}

@export var card_name : CardName


func apply(source, target, combat):
	if card_name == CardName.ABJURATION:
		if source and source.has_method("add_strike_damage") and source.has_method("get_block"):
			var block_damage = source.get_block()
			source.add_strike_damage(block_damage, false)

	if card_name == CardName.DIVINE_INCANTATION:
		if source:
			source.status_effects["empower"] *= 2
	
	if card_name == CardName.DUPLICATE:
		# For now, just duplicate the first card in hand (can be replaced with selection logic)
		var hand = combat.deck.hand if combat.deck and combat.deck.hand != null else []
		if hand.size() == 0:
			print("[DuplicateEffect] No cards in hand to duplicate.")
			return
		var card_to_duplicate = hand[0]
		if card_to_duplicate == null or card_to_duplicate.data == null:
			print("[DuplicateEffect] Invalid card to duplicate.")
			return
		# Clone the card data and set as temporary
		var temp_card_data = card_to_duplicate.data.duplicate()
		temp_card_data.temporary = true
		# Create a new CardInstance with the temp data
		var temp_card_instance = CardInstance.new(temp_card_data)
		# Add to draw_pile so it will be in the deck for the rest of battle
		combat.deck.draw_pile.append(temp_card_instance)
		# Add to hand so it appears immediately
		combat.deck.hand.append(temp_card_instance)
		combat.spawn_card(temp_card_instance)
		print("[DuplicateEffect] Duplicated card added as temporary to draw_pile and hand.")
	
	if card_name == CardName.FIRE_BOLT:
		if target and target.has_method("get_burn"):
			if source and source.has_method("add_strike_status"):
				if target.get_burn() > 0:
					source.add_strike_status("burn", 2)
				else:
					source.add_strike_status("burn", 1)
	
	if card_name == CardName.GRAND_FINALE:
		if target and target.has_method("get_burn") and target.has_method("get_shock"):
			if source and source.has_method("add_strike_damage"):
				if target.get_burn() > 0:
					for i in range(target.get_burn()):
						source.add_strike_damage(3)
				if target.get_shock() > 0:
					for i in range(target.get_shock()):
						source.add_strike_damage(3)
	
	if card_name == CardName.LAY_ON_HANDS:
		if source and "status_effects" in source:
			var count : int = 0
			for effect in source.status_effects:
				count += source.status_effects[effect]
				source.status_effects[effect] = 0
			
			source.status_effects["empower"] = count
			
		if source and source.has_method("add_block"):
			source.add_block(6)
	
	if card_name == CardName.LIGHTNING_STRIKE:
		if target and target.has_method("get_shock"):
			if source and source.has_method("add_energy"):
				if target.get_shock() > 0:
					source.add_energy(1)
			
			if source and source.has_method("add_strike_status"):
				source.add_strike_status("shock", 2)
	
	if card_name == CardName.POTENTIAL_DESTRUCTION:
		if source and source.has_method("add_strike_damage") and source.has_method("get_damage"):
			source.add_strike_damage(source.potential_destruction, false)
			source.potential_destruction += source.get_damage()
	
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
	
	if card_name == CardName.STATIC_FIELD:
		if target and target.has_method("get_shock") and source and source.has_method("add_energy"):
			if target.get_shock() > 0:
				source.add_energy(1)
	
	if card_name == CardName.THUNDERWAVE:
		if target and target.has_method("get_shock") and target.has_method("apply_status"):
			if target.get_shock() > 0:
				target.apply_status("stun", 1)
	
