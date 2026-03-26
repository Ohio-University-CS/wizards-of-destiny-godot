# Used to add damage to the Strike

class_name AddStrikeDamageEffect extends Effect

enum Element {
	NONE,
	FIRE,
	ICE,
	POISON,
	ELECTRIC
}

@export var amount : int = 0
@export var times : int = 1
@export var element : Element = Element.NONE
@export var include_base_dmg : bool = false

func apply(source, _target, _combat):
	if source and source.has_method("add_strike_damage"):
		for _i in range(times):
			if element == Element.NONE: # Doesn't need to worry about elemental damage
				source.add_strike_damage(amount, include_base_dmg)
			else: # Handle elemental damage
				var element_str = Element.keys()[element].to_lower()
				source.add_strike_element(element_str, amount, include_base_dmg)
			
