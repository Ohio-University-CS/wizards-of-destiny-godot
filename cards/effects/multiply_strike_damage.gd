# Used to multiply all damage done by Strike

class_name MultiplyStrikeDamage extends Effect

@export var amount : float = 1


func apply(_source, _target, _combat):
	if _source and _source.has_method("multiply_strike_damage"):
		_source.multiply_strike_damage(amount)
