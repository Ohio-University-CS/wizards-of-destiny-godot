# Essentially used to clone cards
# Prevents actual game data from changing
# Instances are what are put in deck

class_name CardInstance
extends RefCounted

var data: CardData
var exhausted: bool = false


func _init(card_data: CardData):
	data = card_data


func play(_target, caster) -> bool:
	if caster.energy < data.energy_cost:
		return false

	if caster.has_method("spend_energy"):
		if not caster.spend_energy(data.energy_cost):
			return false
	else:
		caster.energy -= data.energy_cost
		
	if data.card_flag == CardData.CardFlag.RITUAL:
		exhausted = true
	
	return true


func set_exhaust_flag():
	exhausted = true
