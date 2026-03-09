class_name CardInstance
extends RefCounted

var data: CardData
var exhausted: bool = false


func _init(card_data: CardData):
	data = card_data


func play(target, caster) -> bool:
	if caster.energy < data.energy_cost:
		return false

	if caster.has_method("spend_energy"):
		if not caster.spend_energy(data.energy_cost):
			return false
	else:
		caster.energy -= data.energy_cost
	
	for effect in data.effects:
		resolve_effect(effect, target, caster)
	
	if data.card_flag == CardData.CardFlag.RITUAL:
		exhausted = true
	
	if data.card_flag == CardData.CardFlag.PASSIVE:
		# handled elsewhere (persistent effect system)
		pass
	
	return true


func resolve_effect(effect, target, caster):
	if randf() > effect.chance:
		return
	match effect.effect_type:
		EffectData.EffectType.DAMAGE:
			for i in range(effect.hits):
				var total = caster.deal_damage(effect.amount, effect.stat_name)
				target.take_damage(total)
		
		EffectData.EffectType.BLOCK:
			caster.add_block(effect.amount)
		
		EffectData.EffectType.APPLY_STATUS:
			target.apply_status(effect.status_name, effect.amount)
		
		EffectData.EffectType.MODIFY_STAT:
			caster.modify_stat(effect.stat_name, effect.amount)
		
		EffectData.EffectType.TEMP_STAT:
			caster.modify_stat_temp(effect.stat_name, effect.amount, effect.duration_turns)
		
		EffectData.EffectType.MULTIPLIER_DAMAGE:
			var total = caster.deal_damage(
				caster.get_stat(effect.stat_name) * effect.multiplier
			)
			target.take_damage(total)
