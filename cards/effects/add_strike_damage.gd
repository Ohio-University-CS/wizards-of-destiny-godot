class_name AddStrikeDamageEffect extends Effect

@export var amount : int = 0

func apply(source, _target, _combat):
	if source and source.has_method("add_strike_damage"):
		source.add_strike_damage(amount)
