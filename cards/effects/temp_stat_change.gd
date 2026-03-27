class_name TempStatChange extends Effect

enum Stat {
	max_health,
	damage,
	elemental_power,
	fire,
	ice,
	poison,
	electric,
	crit_damage,
	crit_chance,
	dodge
}

@export var stat : Stat
@export var amount : int


func apply(source, _target, _combat):
	if source and source.has_method("modify_stat_temp"):
		source.modify_stat_temp(str(stat), amount)
