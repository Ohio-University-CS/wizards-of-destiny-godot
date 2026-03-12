extends Node
class_name Enemy

# ---------------------------------------------------------
# ENEMY STATS (Base + Modifiers)
# ---------------------------------------------------------

var class_data: ClassData

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

# Predefined enemy categories with sensible defaults
const CATEGORY_STATS = {
	"Goblin": {
		"max_health": 18,
		"damage": 3,
		"fire_power": 0,
		"ice_power": 0,
		"poison_power": 1,
		"electric_power": 0,
		"heal_power": 0,
		"shield": 0,
		"max_energy": 2,
		"dodge_chance": 0.05,
		"crit_chance": 0.05,
		"crit_damage": 1.5,
		"luck": 0.02
	},
	"Wizard": {
		"max_health": 16,
		"damage": 2,
		"fire_power": 3,
		"ice_power": 2,
		"poison_power": 0,
		"electric_power": 2,
		"heal_power": 1,
		"shield": 0,
		"max_energy": 4,
		"dodge_chance": 0.04,
		"crit_chance": 0.08,
		"crit_damage": 1.6,
		"luck": 0.05
	},
	"Robot": {
		"max_health": 30,
		"damage": 6,
		"fire_power": 0,
		"ice_power": 0,
		"poison_power": 0,
		"electric_power": 3,
		"heal_power": 0,
		"shield": 2,
		"max_energy": 3,
		"dodge_chance": 0.02,
		"crit_chance": 0.03,
		"crit_damage": 1.4,
		"luck": 0.01
	}
}

# Human-friendly category label
@export var category: String = "Goblin"
@export var dodge_chance: float = 0.0 # 0–0.50
@export var crit_chance: float = 0.0 # 0–0.40
@export var crit_damage: float = 1.5 # multiplier
@export var luck: float = 0.0 # 0–0.70

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


func configure_from_category(cat: String) -> void:
	# Apply presets from CATEGORY_STATS. Falls back to Goblin if missing.
	var stats = CATEGORY_STATS.get(cat, CATEGORY_STATS["Goblin"])

	base_max_health = stats["max_health"]
	base_damage = stats["damage"]
	base_fire_power = stats["fire_power"]
	base_ice_power = stats["ice_power"]
	base_poison_power = stats["poison_power"]
	base_electric_power = stats["electric_power"]
	base_heal_power = stats["heal_power"]
	base_shield = stats["shield"]

	max_energy = stats["max_energy"]
	energy = max_energy
	dodge_chance = stats["dodge_chance"]
	crit_chance = stats["crit_chance"]
	crit_damage = stats["crit_damage"]
	luck = stats["luck"]

	current_health = get_max_health()
	category = cat
	emit_signal("energy_changed", energy, max_energy)


static func new_enemy(cat: String) -> Enemy:
	var e = Enemy.new()
	e.configure_from_category(cat)
	return e


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
	return base_heal_power + temp_modifiers["heal"]

func get_shield() -> int:
	return base_shield + temp_modifiers["shield"]

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
