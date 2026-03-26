extends Node
class_name Player

# ---------------------------------------------------------
# PLAYER STATS (Base + Modifiers)
# ---------------------------------------------------------


var class_data

# List of active passive cards/effects
var active_passives: Array = []

@export var initialized : bool = false

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


func setup_from_class(data):
	if data == null:
		push_error("Player.setup_from_class called with null class data")
		return

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
	initialized = true
	emit_signal("health_changed", current_health)
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
			add_strike_damage(amount, false)
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

signal strike_changed(total_damage)

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
	
	_emit_strike_changed()

#add normal damage to strike
func add_strike_damage(amount: int, _include_base_dmg : bool):
	strike_bonus_damage += amount
	if _include_base_dmg:
		strike_bonus_damage += get_damage()
	_emit_strike_changed()

func multiply_strike_damage(amount : float):
	@warning_ignore("narrowing_conversion")
	strike_bonus_damage *= amount
	@warning_ignore("narrowing_conversion")
	strike_bonus_damage += ((get_damage() * amount) - get_damage()) #adds multiplied base strike damage
	for element in strike_elemental_damage:
		if strike_elemental_damage[element] != 0:
			strike_elemental_damage[element] *= amount
	
	_emit_strike_changed()


#add elemental damage to strike
func add_strike_element(element: String, amount: int, _include_base_dmg : bool):
	if strike_elemental_damage.has(element):
		strike_elemental_damage[element] += amount
		if _include_base_dmg:
			strike_elemental_damage[element] += get_damage()
	
	_emit_strike_changed()

#add status effect to strike
func add_strike_status(status: String, stacks: int):
	strike_statuses.append({
		"name": status,
		"stacks": stacks
	})

#handle multiplying damage
func apply_damage_multiplier(mult: float):
	damage_multiplier *= mult


func _emit_strike_changed():
	var total = get_damage() + strike_bonus_damage
	emit_signal("strike_changed", total)


var _strike_in_progress := false

#perform the actual strike

func perform_strike(target):
	# Prevent strike if Broken is active
	if status_effects["broken"] > 0:
		print("Strike prevented: Player is Broken.")
		return
	_strike_in_progress = true
	_do_strike_on_target(target)
	# If Surge is active, hit again
	if active_passives.has("Surge"):
		print("Surge active: Strike hits twice!")
		active_passives.erase("Surge")
		_do_strike_on_target(target)
	_strike_in_progress = false

# Helper for strike logic (all effects)
func _do_strike_on_target(target):
	var dmg = get_damage() + strike_bonus_damage
	# Empower: +3 damage per stack
	if status_effects["empower"] > 0:
		dmg += 3 * status_effects["empower"]
	# Apply Freeze: -2 per stack, cannot go below 0
	var freeze_stacks = status_effects["freeze"]
	if freeze_stacks > 0:
		dmg = max(0, dmg - 2 * freeze_stacks)
		status_effects["freeze"] = 0
		emit_signal("status_expired", "freeze")
	# Apply Shock: take stack amount of Lightning damage, remove one stack
	var shock_stacks = status_effects["shock"]
	if shock_stacks > 0:
		take_damage(shock_stacks, "electric")
		status_effects["shock"] -= 1
		if status_effects["shock"] == 0:
			emit_signal("status_expired", "shock")
	dmg = int(dmg * damage_multiplier)
	#deal normal damage once
	if dmg > 0:
		target.take_damage(dmg)
	#elemental damage
	for element in strike_elemental_damage.keys():
		var amt = strike_elemental_damage[element]
		if amt > 0:
			var elemental_dmg = deal_damage(amt, element)
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
	"stun": 0, # skips turn
	"broken": 0, # strike doesn't trigger (max 1)
	"empower": 0 # deal +3 damage per stack, remove 1 at end of turn
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
	if not initialized:
		return
	
	set_energy(max_energy)


# ---------------------------------------------------------
# COMBAT INTERFACE
# ---------------------------------------------------------

func start_turn():
	# Stun: skip turn if stunned, remove one stack
	if status_effects["stun"] > 0:
		status_effects["stun"] -= 1
		if status_effects["stun"] == 0:
			emit_signal("status_expired", "stun")
		return

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
	# Empower: remove one stack at end of turn
	if status_effects["empower"] > 0:
		status_effects["empower"] -= 1
		if status_effects["empower"] == 0:
			emit_signal("status_expired", "empower")
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
	# Corroded: +2 damage taken per stack, remove one stack after being hit
	if status_effects["corroded"] > 0:
		dmg += 2 * status_effects["corroded"]
		status_effects["corroded"] -= 1
		if status_effects["corroded"] == 0:
			emit_signal("status_expired", "corroded")

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
	# Sealed: Only Strike deals damage
	if status_effects["sealed"] > 0 and not _strike_in_progress:
		return 0
	var dmg = amount
	
	if include_base_damage:
		dmg += get_damage()
	
	# Empower: +3 damage per stack
	if status_effects["empower"] > 0:
		dmg += 3 * status_effects["empower"]
	
	#Elemental bonuses
	match element:
		"fire": dmg += get_fire_power()
		"ice": dmg += get_ice_power()
		"poison": dmg += get_poison_power()
		"electric": dmg += get_electric_power()
	
	# Freeze does not affect elemental damage (handled in perform_strike)
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
	# Clamp Broken to max 1 stack
	if status_name == "broken":
		status_effects[status_name] = clamp(status_effects[status_name], 0, 1)
	emit_signal("status_applied", status_name, status_effects[status_name])
	if status_effects["broken"] > 0:
		return


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
		if status_effects["burn"] == 0:
			emit_signal("status_expired", "burn")


func _apply_heal():
	if status_effects["regeneration"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["regeneration"])
		emit_signal("health_changed", current_health)


func _apply_shock():
	if status_effects["shock"] > 0:
		# Shock reduces energy
		set_energy(max(0, energy - status_effects["shock"]))


func set_energy(new_value: int) -> void:
	energy = max(0, new_value) # Only clamp to zero, not max_energy
	emit_signal("energy_changed", energy, max_energy)


func add_energy(amount : int) -> void:
	set_energy(energy + amount)


func spend_energy(amount: int) -> bool:
	if amount > energy:
		return false
	set_energy(energy - amount)
	return true


# temporary passive (rituals, etc)
func _add_temp_effect(ename : String):
	active_passives.append(ename)


# Registers a passive card/effect if not already present
func register_passive(pname : String) -> void:
	# this is in case we don't want duplicates
	#if card in active_passives:
		#return # Prevent duplicates
	active_passives.append(pname)
	# Optionally, trigger any setup logic for the passive here


# ---------------------------------------------------------
# UTILITY
# ---------------------------------------------------------

func is_stunned() -> bool:
	return status_effects["stun"] > 0


func try_dodge() -> bool:
	return randf() < get_dodge_chance()


func _die():
	emit_signal("died")
