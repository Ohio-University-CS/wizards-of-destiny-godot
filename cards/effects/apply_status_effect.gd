# Used to apply status effects to player or enemy

class_name ApplyStatusEffect extends Effect

enum StatusType {
	NONE,
	BURN,
	FREEZE,
	CORRODED,
	SHOCK,
	REGENERATION,
	STUN,
	DRAINED,
	SEALED,
	EMPOWER,
	EVASIVE
}

@export var status_type : StatusType = StatusType.NONE
@export var amount : int = 0

func apply(_source, target, _combat):
	var status_name = StatusType.keys()[status_type].to_lower()
	target.apply_status(status_name, amount)
	
	# Electrostasis Passive
	if status_type == StatusType.SHOCK:
		if _source.has_var("active_passives"):
			if _source.active_passives.has("Electrostasis") and _source.electrostasis == false:
				_source.add_energy(1)
				_source.electrostasis = true
