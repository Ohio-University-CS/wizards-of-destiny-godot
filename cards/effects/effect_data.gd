extends Resource
class_name EffectData

#-------------
# Variables
#-------------

enum EffectType {
	DAMAGE,
	BLOCK,
	APPLY_STATUS,
	MODIFY_STAT,
	ADD_STRIKE_DAMAGE,
	MULTIPLIER_DAMAGE,
	
	DRAW_CARDS,
	DISCARD_CARDS,
	GAIN_ENERGY,
	
	EXHAUST_SELF
}

enum StatusType {
	NONE,
	BURN,
	BLOCK,
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

enum StatType {
	NONE,
	STRIKE_DAMAGE,
	DRAW,
	ENERGY,
	DODGE
}

@export var effect_type: EffectType

@export var amount : int = 0
@export var multiplier : float = 1.0
@export var hits : int = 1
@export var chance : float = 1.0

@export var element : String = ""
@export var include_base_damage : bool = false

@export var status_type : StatusType
@export var stat_type : StatType

@export var duration_turns : int = 0

@export var tags : Array[String] = []

#-------------
# Functions
#-------------

func get_status_name() -> String:
	return StatusType.keys()[status_type].to_lower()

func get_stat_name() -> String:
	return StatType.keys()[stat_type]

#func apply(source, target, combat)
