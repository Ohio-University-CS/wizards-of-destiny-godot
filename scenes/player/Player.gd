extends Node
class_name Player

# ---------------------------------------------------------
# PLAYER STATS (Base + Modifiers)
# ---------------------------------------------------------

var class_data

# BASE STATS (from class)
var base_max_health: int
var base_damage: int
var base_elemental_power: int
var base_fire: int
var base_ice: int
var base_poison: int
var base_electric: int
var base_crit_damage: int
var base_crit_chance: float
var base_dodge: float

# PERMANENT MODIFIERS (artifacts/upgrades)
var perm_modifiers := {
	"max_health": 0,
	"damage": 0,
	"elemental_power": 0,
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0,
	"crit_damage": 0,
	"crit_chance": 0,
	"dodge": 0
}

var temp_modifiers := {
	"max_health": 0,
	"damage": 0,
	"elemental_power": 0,
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0,
	"crit_damage": 0,
	"crit_chance": 0,
	"dodge": 0
}

@export var luck: float = 0.0 # 0-0.70

# Runtime values
var current_health: int
var energy: int = 3
var max_energy: int = 3

var deck_list : Array[CardData] = []

var coins : int = 0


func setup_from_class(data):
	class_data = data
	
	deck_list = data.starting_deck.duplicate()
	
	base_max_health = data.max_health
	base_damage = data.damage
	base_elemental_power = data.elemental_power
	base_crit_damage = data.crit_damage
	base_crit_chance = data.crit_chance
	base_dodge = data.dodge
	
	base_fire = 0
	base_ice = 0
	base_poison = 0
	base_electric = 0

	max_energy = data.max_energy
	energy = max_energy
	current_health = get_max_health()
	emit_signal("energy_changed", energy, max_energy)


func get_max_health() -> int:
	return base_max_health + perm_modifiers["max_health"] + temp_modifiers["max_health"]

func get_damage() -> int:
	return base_damage + perm_modifiers["damage"] + temp_modifiers["damage"]

func get_crit_damage() -> int:
	return base_crit_damage + perm_modifiers["crit_damage"] + temp_modifiers["crit_damage"]

func get_crit_chance() -> float:
	return base_crit_chance + perm_modifiers["crit_chance"] + temp_modifiers["crit_chance"]

func get_dodge_chance() -> float:
	return base_dodge + perm_modifiers["dodge"] + temp_modifiers["dodge"]

func get_elemental_power() -> float:
	return base_elemental_power + perm_modifiers["elemental_power"] + temp_modifiers["elemental_power"]

func get_fire_power() -> int:
	var total_fire: int = base_fire + perm_modifiers["fire"] + temp_modifiers["fire"]
	@warning_ignore("narrowing_conversion") # script doesn't like float to int conversion, but we need it
	return total_fire + (total_fire * get_elemental_power())

func get_ice_power() -> int:
	var total_ice: int = base_ice + perm_modifiers["ice"] + temp_modifiers["ice"]
	@warning_ignore("narrowing_conversion")
	return total_ice + (total_ice * get_elemental_power())

func get_poison_power() -> int:
	var total_poison: int = base_poison + perm_modifiers["poison"] + temp_modifiers["poison"]
	@warning_ignore("narrowing_conversion")
	return total_poison + (total_poison * get_elemental_power())

func get_electric_power() -> int:
	var total_electric: int = base_electric + perm_modifiers["electric"] + temp_modifiers["electric"]
	@warning_ignore("narrowing_conversion")
	return total_electric + (total_electric * get_elemental_power())

func modify_stat_permanent(stat_name: String, amount: int):
	if perm_modifiers.has(stat_name):
		perm_modifiers[stat_name] += amount

		# If max health increases, optionally heal player
		if stat_name == "max_health":
			current_health = clamp(current_health + amount, 0, get_max_health())


func modify_stat(stat_type, amount: int, duration_turns: int = 0):
	var stat_name := ""
	
	match stat_type:
		"ENERGY":
			set_energy(energy + amount)
			return
		"DRAW":
			stat_name = "draw"
		"STRIKE_DAMAGE":
			add_strike_damage(amount)
			return
		_:
			stat_name = str(stat_type).to_lower()
	
	if duration_turns > 0:
		modify_stat_temp(stat_name, amount)
	else:
		modify_stat_permanent(stat_name, amount)


# ---------------------------------------------------------
# STRIKE SYSTEM
# ---------------------------------------------------------

var strike_bonus_damage: int = 0
var strike_elemental_damage := {
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0
}
var strike_statuses: Array = []
var damage_multiplier: float = 1.0

#reset all strike at start of turn
func reset_strike():
	strike_bonus_damage = 0
	strike_statuses.clear()
	for element in strike_elemental_damage.keys():
		strike_elemental_damage[element] = 0

#add normal damage to strike
func add_strike_damage(amount: int):
	strike_bonus_damage += amount

#add elemental damage to strike
func add_strike_element(element: String, amount: int):
	if strike_elemental_damage.has(element):
		strike_elemental_damage[element] += amount

#add status effect to strike
func add_strike_status(status: String, stacks: int):
	strike_statuses.append({
		"name": status,
		"stacks": stacks
	})

#handle multiplying damage
func apply_damage_multiplier(mult: float):
	damage_multiplier *= mult

#perform the actual strike
func perform_strike(target):
	#normal damage
	var dmg = get_damage() + strike_bonus_damage
	dmg = int(dmg * damage_multiplier)
	#deal normal damage once
	if dmg > 0:
		target.take_damage(dmg)
	print("Strike deals ", dmg, " damage")
	
	#elemental damage
	for element in strike_elemental_damage.keys():
		var amt = strike_elemental_damage[element]
		if amt > 0:
			var elemental_dmg = deal_damage(amt, element)
			#APPLY FREEZE/CRIT LATER DOWN THE LINE
			target.take_damage(elemental_dmg, element)
			print(" - Deals ", elemental_dmg, " ", element, " damage")
	
	#status effects
	for effect in strike_statuses:
		target.apply_status(effect["name"], effect["stacks"])
		print(" - Apply ", effect["name"], " x", effect["stacks"])
	
	damage_multiplier = 1.0


# ---------------------------------------------------------
# STATUS EFFECTS
# ---------------------------------------------------------

var temp_stat_modifiers := {}

var status_effects := {
	"burn": 0, # take fire damage per completed turn
	"regeneration": 0, # regain hp
	"block": 0, # decreases damage taken
	"drained": 0, # draws less cards
	"freeze": 0, # decrease outgoing damage
	"corroded": 0, # increase incoming damage
	"sealed": 0, # can't deal damage outside of strike
	"shock": 0, # take damage when dealing damage
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
signal damaged(amount)
signal healed(amount)

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
	
	#Reset Strike
	reset_strike()
	
	for element in strike_elemental_damage.keys():
		strike_elemental_damage[element] = 0

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
	if try_dodge():
		return
	
	var dmg = amount

	# Freeze reduces outgoing damage, not incoming
	# Corroded increases incoming damage, stacks
	if status_effects["corroded"] > 0:
		var multiplier = 1.0 + (0.10 * status_effects["corroded"])
		dmg = int(dmg * multiplier)

	# Block reduces damage
	if status_effects["block"] > 0:
		var block_amt = status_effects["block"]
		var reduced = min(block_amt, dmg)
		dmg -= reduced
		status_effects["block"] -= reduced

	current_health -= dmg
	emit_signal("health_changed", current_health)
	# Emit damaged for UI indicators
	emit_signal("damaged", dmg)

	if current_health <= 0:
		_die()


func deal_damage(amount: int, element: String = "", include_base_damage: bool = true) -> int:
	var dmg = amount
	
	if include_base_damage:
		dmg += get_damage()
	
	#Elemental bonuses
	match element:
		"fire": dmg += get_fire_power()
		"ice": dmg += get_ice_power()
		"poison": dmg += get_poison_power()
		"electric": dmg += get_electric_power()
	
	#Freeze reduces outgoing damage by 10% per stack
	var freeze_stacks = status_effects["freeze"]
	if freeze_stacks > 0:
		var multiplier = 1.0 - (0.1 * freeze_stacks)
		multiplier = max(multiplier, 0.4) # can't drop below 40%
		dmg = int(dmg * multiplier)
	
	#Crit check
	if randf() < get_crit_chance():
		dmg += get_crit_damage()
	
	return dmg


func heal(amount: int):
	current_health = min(get_max_health(), current_health + amount)
	emit_signal("health_changed", current_health)
	emit_signal("healed", amount)

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


func has_status(status_name: String) -> bool:
	return status_effects.get(status_name, 0) > 0

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
		status_effects["burn"] -= 1


func _apply_heal():
	if status_effects["regeneration"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["regeneration"])
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
	return randf() < get_dodge_chance()


func _die():
	emit_signal("died")
