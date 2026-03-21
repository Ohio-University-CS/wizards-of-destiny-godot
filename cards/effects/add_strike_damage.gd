class_name AddStrikeDamageEffect extends Effect

@export var amount : int = 0
@export var times : int = 1

func apply(source, _target, _combat):
	if source and source.has_method("add_strike_damage"):
		for _i in range(times):
			source.add_strike_damage(amount)
