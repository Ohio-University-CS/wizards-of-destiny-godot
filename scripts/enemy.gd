extends Node
class_name Enemy

# ---------------------------------------------------------
# ENEMY STATS (Base + Modifiers)
# ---------------------------------------------------------

var class_data : ClassData

# BASE STATS (from class)
var base_max_health: int
var base_damage: int
var base_fire_power: int
var base_ice_power: int
var base_poison_power: int
var base_electric_power: int
var base_heal_power: int
var base_shield: int


var temp_modifiers := {
	"max_health": 0,
	"damage": 0,
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0,
	"heal": 0,
	"shield": 0
}

@export var dodge_chance: float = 0.0   # 0–0.50
@export var crit_chance: float = 0.0    # 0–0.40
@export var crit_damage: float = 1.5    # multiplier
@export var luck: float = 0.0           # 0–0.70

# Runtime values
var current_health: int
var energy: int = 3
var max_energy: int = 3


func setup_from_class(data: ClassData):
	class_data = data

	base_max_health = data.max_health
	base_damage = data.damage
	base_fire_power = data.fire_power
	base_ice_power = data.ice_power
	base_poison_power = data.poison_power
	base_electric_power = data.electric_power
	base_heal_power = data.heal_power
	base_shield = data.shield

	max_energy = data.max_energy
	current_health = get_max_health()


func get_max_health() -> int:
	return base_max_health + temp_modifiers["max_health"]

func get_damage() -> int:
	return base_damage + temp_modifiers["damage"]

func get_fire_power() -> int:
	return base_fire_power + temp_modifiers["fire"]

func get_ice_power() -> int:
	return base_ice_power + temp_modifiers["ice"]

func get_poison_power() -> int:
	return base_poison_power + temp_modifiers["poison"]

func get_electric_power() -> int:
	return base_electric_power + temp_modifiers["electric"]

func get_heal_power() -> int:
	return base_heal_power +temp_modifiers["heal"]

func get_shield() -> int:
	return base_shield + temp_modifiers["shield"]

# ---------------------------------------------------------
# STATUS EFFECTS
# ---------------------------------------------------------

var temp_stat_modifiers := {}

var status_effects := {
	"burn": 0,
	"heal": 0,
	"block": 0,
	"drained": 0,
	"freeze": 0,
	"poison": 0,
	"shock": 0,
	"stun": 0
}

# ---------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------

signal health_changed(new_value)
signal died
signal status_applied(name, stacks)
signal status_expired(name)

# ---------------------------------------------------------
# INITIALIZATION
# ---------------------------------------------------------

func _ready():
	current_health = get_max_health()


# ---------------------------------------------------------
# COMBAT INTERFACE
# ---------------------------------------------------------

func start_turn():
	# Apply start-of-turn effects
	_apply_heal()
	_apply_shock()

	# Reset block each turn
	status_effects["block"] = 0

	# Draw cards handled by CombatManager
	# Energy reset
	energy = max_energy


func end_turn():
	_apply_burn()
	_clear_temp_stats()


func _clear_temp_stats():
	for key in temp_modifiers.keys():
		temp_modifiers[key] = 0

# ---------------------------------------------------------
# DAMAGE & DEFENSE
# ---------------------------------------------------------

func take_damage(amount: int, element: String = ""):
	var dmg = amount

	# Freeze reduces outgoing damage, not incoming
	# Poison increases incoming damage, stacks
	if status_effects["poison"] > 0:
		var multiplier = 1.0 + (0.10 * status_effects["poison"])
		dmg = int(dmg * multiplier)

	# Block reduces damage
	if status_effects["block"] > 0:
		var block_amt = status_effects["block"]
		var reduced = min(block_amt, dmg)
		dmg -= reduced
		status_effects["block"] -= reduced

	current_health -= dmg
	emit_signal("health_changed", current_health)

	if current_health <= 0:
		_die()


func deal_damage(amount: int, element: String = "") -> int:
	var dmg = amount + get_damage()

	# Elemental bonuses
	match element:
		"fire": dmg += get_fire_power()
		"ice": dmg += get_ice_power()
		"poison": dmg += get_poison_power()
		"electric": dmg += get_electric_power()

	# Freeze reduces outgoing damage
	if status_effects["freeze"] > 0:
		dmg = int(dmg * 0.5)

	# Crit check
	if randf() < crit_chance:
		dmg = int(dmg * crit_damage)

	return dmg


# ---------------------------------------------------------
# STATUS EFFECT MANAGEMENT
# ---------------------------------------------------------

func apply_status(name: String, stacks: int = 1):
	if not status_effects.has(name):
		return

	status_effects[name] += stacks
	emit_signal("status_applied", name, status_effects[name])


func clear_status(name: String):
	if status_effects[name] > 0:
		status_effects[name] = 0
		emit_signal("status_expired", name)


# ---------------------------------------------------------
# STATUS EFFECT LOGIC
# ---------------------------------------------------------

func modify_stat_temp(stat_name: String, amount: int):
	if temp_modifiers.has(stat_name):
		temp_modifiers[stat_name] += amount


func add_block(amount: int):
	status_effects["block"] += amount


func _apply_burn():
	if status_effects["burn"] > 0:
		take_damage(status_effects["burn"])


func _apply_heal():
	if status_effects["heal"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["heal"])
		emit_signal("health_changed", current_health)


func _apply_shock():
	if status_effects["shock"] > 0:
		# Shock reduces energy
		energy = max(0, energy - status_effects["shock"])


# ---------------------------------------------------------
# UTILITY
# ---------------------------------------------------------

func is_stunned() -> bool:
	return status_effects["stun"] > 0


func try_dodge() -> bool:
	return randf() < dodge_chance


func _die():
	emit_signal("died")
