class_name ChoiceEffect extends Effect

enum CardName {
	CURSE,
	ELEMENTAL_STORM,
	ENCHANT,
	FIRE_STORM,
	MYSTIC_BOLT,
	SPARK_OF_MAGIC
}

@export var card_name : CardName

var choice_amount : int = 2
var max_choices : int = 1

var choice_texts : Array[String]


func apply(_source, _target, _combat):
	if card_name == CardName.CURSE:
		choice_texts.append("Double all Burn on Enemy")
		choice_texts.append("Double all Shock on Enemy")
	
	if card_name == CardName.ELEMENTAL_STORM:
		choice_texts.append("Add 2 Burn to Strike")
		choice_texts.append("Add 2 Shock to Strike")
	
	if card_name == CardName.ENCHANT:
		choice_texts.append("Apply 4 Burn")
		choice_texts.append("Apply 4 Shock")
	
	if card_name == CardName.FIRE_STORM:
		choice_texts.append("Gain +2 Fire Damage")
		choice_texts.append("Gain +2 Electric Damage")
	
	if card_name == CardName.MYSTIC_BOLT or card_name == CardName.SPARK_OF_MAGIC:
		choice_texts.append("Apply 2 Burn")
		choice_texts.append("Apply 2 Shock")
	
	UIManager.show_card_choice(choice_texts, _on_choice_made.bind(_source, _target, _combat))


func _on_choice_made(index, _source, _target, _combat):
	if card_name == CardName.ELEMENTAL_STORM:
		if index == 0:
			# Double all Burn
			if _target:
				_target.status_effects["burn"] *= 2
		elif index == 1:
			# Double all Shock
			if _target:
				_target.status_effects["shock"] *= 2
	
	if card_name == CardName.ELEMENTAL_STORM:
		if index == 0:
			# Add 2 Burn to Strike
			if _source.has_method("add_strike_status"):
				_source.add_strike_status("burn", 2)
		elif index == 1:
			# Add 2 Shock to Strike
			if _source.has_method("apply_status"):
				_source.add_strike_status("shock", 2)
	
	if card_name == CardName.ENCHANT:
		if index == 0:
			# Apply 2 Burn to target
			if _target.has_method("apply_status"):
				_target.apply_status("burn", 4)
		elif index == 1:
			# Apply 2 Shock to target
			if _target.has_method("apply_status"):
				_target.apply_status("shock", 4)
	
	if card_name == CardName.FIRE_STORM:
		if index == 0:
			# Gain +2 Fire Damage
			if _source and _source.has_method("modify_stat_temp"):
				_source.modify_stat_temp("fire", 2)
		elif index == 1:
			# Gain +2 Electric Damage
			if _source and _source.has_method("modify_stat_temp"):
				_source.modify_stat_temp("electric", 2)
	
	if card_name == CardName.MYSTIC_BOLT or card_name == CardName.SPARK_OF_MAGIC:
		if index == 0:
			# Apply 2 Burn to target
			if _target.has_method("apply_status"):
				_target.apply_status("burn", 2)
		elif index == 1:
			# Apply 2 Shock to target
			if _target.has_method("apply_status"):
				_target.apply_status("shock", 2)
	
