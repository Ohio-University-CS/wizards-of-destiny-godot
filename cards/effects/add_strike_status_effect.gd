# Used to add status effects to Strike

class_name AddStrikeStatusEffect extends Effect

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
	EVASIVE,
	RAGE,
	BROKEN
}

@export var status_type : StatusType = StatusType.NONE
@export var amount : int = 0

func apply(source, _target, _combat):
	if source and source.has_method("add_strike_status"):
		var status_name = StatusType.keys()[status_type].to_lower()
		source.add_strike_status(status_name, amount)
