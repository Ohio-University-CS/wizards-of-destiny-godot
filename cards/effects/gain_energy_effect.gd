# Used to gain energy

class_name GainEnergyEffect extends Effect

@export var amount : int = 1


func apply(_source, _target, _combat):
	if _target:
		_target.add_energy(amount)
