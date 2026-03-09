extends Node
class_name Player

# ---------------------------------------------------------
# PLAYER STATS (Base + Modifiers)
# ---------------------------------------------------------

var class_data

# BASE STATS (from class)
var base_max_health: int
var base_damage: int
var base_fire_power: int
var base_ice_power: int
var base_poison_power: int
var base_electric_power: int
var base_heal_power: int
var base_shield: int

# PERMANENT MODIFIERS (artifacts/upgrades)
var perm_modifiers := {
	"max_health": 0,
	"damage": 0,
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0,
	"heal": 0,
	"shield": 0
}

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

@export var dodge_chance: float = 0.0 # 0-0.50
@export var crit_chance: float = 0.0 # 0-0.40
@export var crit_damage: float = 1.5 # multiplier
@export var luck: float = 0.0 # 0-0.70

# Runtime values
var current_health: int
var energy: int = 3
var max_energy: int = 3


func setup_from_class(data):
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
	energy = max_energy
	current_health = get_max_health()
	emit_signal("energy_changed", energy, max_energy)


func get_max_health() -> int:
	return base_max_health + perm_modifiers["max_health"] + temp_modifiers["max_health"]

func get_damage() -> int:
	return base_damage + perm_modifiers["damage"] + temp_modifiers["damage"]

func get_fire_power() -> int:
	return base_fire_power + perm_modifiers["fire"] + temp_modifiers["fire"]

func get_ice_power() -> int:
	return base_ice_power + perm_modifiers["ice"] + temp_modifiers["ice"]

func get_poison_power() -> int:
	return base_poison_power + perm_modifiers["poison"] + temp_modifiers["poison"]

func get_electric_power() -> int:
	return base_electric_power + perm_modifiers["electric"] + temp_modifiers["electric"]

func get_heal_power() -> int:
	return base_heal_power + perm_modifiers["heal"] + temp_modifiers["heal"]

func get_shield() -> int:
	return base_shield + perm_modifiers["shield"] + temp_modifiers["shield"]


func modify_stat_permanent(stat_name: String, amount: int):
	if perm_modifiers.has(stat_name):
		perm_modifiers[stat_name] += amount

		# If max health increases, optionally heal player
		if stat_name == "max_health":
			current_health = clamp(current_health + amount, 0, get_max_health())

# ---------------------------------------------------------
# STATUS EFFECTS
# ---------------------------------------------------------

var temp_stat_modifiers := {}

var status_effects := {
	"burn": 0, # take fire damage per completed turn, increases how much damage is dealt to affected
	"heal": 0, # regain hp
	"block": 0, # decreases damage taken
	"drained": 0, # can only do basic attacks
	"freeze": 0, # take small amount of damage per completed turn
	"poison": 0, # take small amount of damage per completed turn, lessens damage to opponent
	"bleed": 0, # take small amount of damage proportional to amount of attacks done in a turn
	"shock": 0, # deals good amount of damage to affected, but supercharges next attack
	"stun": 0 # skips turn
}

# ---------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------

signal health_changed(new_value)
signal energy_changed(new_value, max_value)
signal died
signal status_applied(name, stacks)
signal status_expired(name)

# ---------------------------------------------------------
# INITIALIZATION
# ---------------------------------------------------------

func _ready():
	energy = max_energy
	current_health = get_max_health()
	emit_signal("energy_changed", energy, max_energy)


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
	set_energy(max_energy)


func end_turn():
	_apply_burn()
	_clear_temp_stats()


func _clear_temp_stats():
	for key in temp_modifiers.keys():
		temp_modifiers[key] = 0

# ---------------------------------------------------------
# DAMAGE & DEFENSE
# ---------------------------------------------------------

func take_damage(amount: int, _element: String = ""):
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

func apply_status(status_name: String, stacks: int = 1):
	if not status_effects.has(status_name):
		return

	status_effects[status_name] += stacks
	emit_signal("status_applied", status_name, status_effects[status_name])


func clear_status(status_name: String):
	if status_effects[status_name] > 0:
		status_effects[status_name] = 0
		emit_signal("status_expired", status_name)


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
		set_energy(max(0, energy - status_effects["shock"]))


func set_energy(new_value: int) -> void:
	energy = clamp(new_value, 0, max_energy)
	emit_signal("energy_changed", energy, max_energy)


func spend_energy(amount: int) -> bool:
	if amount > energy:
		return false
	set_energy(energy - amount)
	return true


# ---------------------------------------------------------
# UTILITY
# ---------------------------------------------------------

func is_stunned() -> bool:
	return status_effects["stun"] > 0


func try_dodge() -> bool:
	return randf() < dodge_chance


func _die():
	emit_signal("died")
