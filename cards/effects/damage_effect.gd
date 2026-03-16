class_name DamageEffect extends Effect

enum Element {
	NONE,
	FIRE,
	ICE,
	POISON,
	ELECTRIC
}

@export var amount : int = 0
@export var hits : int = 1
@export var element : Element = Element.NONE
@export var include_base_damage : bool = false

func apply(source, target, _combat):
	
	var element_name = Element.keys()[element].to_lower()
	
	for i in range(hits):
		var dmg = source.deal_damage(
			amount,
			element_name,
			include_base_damage
		)
		
		target.take_damage(dmg)
