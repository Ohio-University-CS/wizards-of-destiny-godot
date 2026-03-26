# Handles non-regeneration heals

class_name HealEffect extends Effect

@export var amount : int = 0

func apply(_source, target, _combat):
	target.heal(amount)
