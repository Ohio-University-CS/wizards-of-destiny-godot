# Handles effects of scrolls in shop
extends Resource
class_name ScrollEffect

enum Stat {
	HEALTH,
	DAMAGE,
	DODGE,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	FIRE,
	ICE,
	POISON,
	ELECTRIC,
	ELEMENTAL_POWER
}

@export var stat : Stat = Stat.HEALTH
@export var amount : int = 1


func apply_scroll():
	if RunManager.player:
		if stat == Stat.HEALTH:
			RunManager.player.base_max_health += amount
			RunManager.player.current_health += amount
		if stat == Stat.DAMAGE:
			RunManager.player.base_damage += amount
		if stat == Stat.DODGE:
			RunManager.player.base_dodge += amount
		if stat == Stat.CRIT_CHANCE:
			RunManager.player.base_crit_chance += amount
		if stat == Stat.CRIT_DAMAGE:
			RunManager.player.base_crit_damage += amount
		if stat == Stat.FIRE:
			RunManager.player.base_fire += amount
		if stat == Stat.ICE:
			RunManager.player.base_ice += amount
		if stat == Stat.POISON:
			RunManager.player.base_poison += amount
		if stat == Stat.ELECTRIC:
			RunManager.player.base_electric += amount
		if stat == Stat.ELEMENTAL_POWER:
			RunManager.player.base_elemental_power += amount
