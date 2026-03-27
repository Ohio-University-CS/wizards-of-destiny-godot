class_name SpecialEffect extends Effect

enum CardName {
	ABJURATION,
	FIRE_BOLT
}

@export var card_name : CardName


func apply(source, target, _combat):
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
