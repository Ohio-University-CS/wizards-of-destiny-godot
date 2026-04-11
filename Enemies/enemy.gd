# Handles enemy

extends Node
class_name Enemy

# ---------------------------------------------------------
# ENEMY STATS (Base + Modifiers)
# ---------------------------------------------------------

@onready var health_bar = $EnemyHealth

var resource: EnemyResource = null
@export var enemy_data: EnemyResource

# BASE STATS (from resource)
var base_max_health: int
var temp_health_mod: int = 0
var base_damage: int = 0

# Runtime values
var current_health: int


var current_move: MoveResource = null
var last_move: MoveResource = null
var repeat_count: int = 0

@export var debug_status_vfx_test: bool = false
@export var debug_test_status: String = "regeneration"
@export var debug_test_stacks: int = 3


func setup_from_resource(res: EnemyResource) -> void:
	resource = res
	base_max_health = res.hp_variation[0]
	
	# Rune of Death
	if RunManager.has_item("Rune of Death"):
		base_max_health -= 3
	
	base_damage = res.base_damage
	current_health = base_max_health


# for use later
func modify_stat(_stat_type, _amount: int, _duration_turns: int = 0):
	pass


func get_max_health() -> int:
	return base_max_health + temp_health_mod


# ---------------------------------------------------------
# STATUS EFFECTS
# ---------------------------------------------------------

var temp_stat_modifiers := {}

var status_effects := {
	"burn": 0, # take fire damage per completed turn
	"regeneration": 0, # regain hp
	"block": 0, # decreases damage taken
	"freeze": 0, # reduce outgoing damage
	"corroded": 0, # increases incoming damage
	"shock": 0, # deals damage when attacking
	"stun": 0, # skips turn
	"empower": 0, # deal +3 damage per stack, remove 1 at end of turn
	"evasive": 0, # dodge next attack, remove a stack (max 2), remove at start of turn
	"rage": 0 # deal +1 damage per stack, doesn't get removed
}


func get_burn() -> int:
	return status_effects["burn"]


func get_shock() -> int:
	return status_effects["shock"]

# ---------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------

signal health_changed(new_value)
signal died
signal status_applied(name, stacks)
signal status_expired(name)
signal damaged(amount)
signal healed(amount)

# ---------------------------------------------------------
# INITIALIZATION
# ---------------------------------------------------------

func _ready():
	if enemy_data != null:
		setup_from_resource(enemy_data)
	elif current_health <= 0:
		current_health = get_max_health()

	# Create StatusVFXHandler as a child node to handle status effect visuals
	var vfx_handler = StatusVFXHandler.new()
	vfx_handler.name = "StatusVFXHandler"
	add_child(vfx_handler)

	if OS.is_debug_build() and debug_status_vfx_test:
		apply_status(debug_test_status, max(debug_test_stacks, 1))
		print("Enemy VFX debug active. Press ] to add stack and [ to clear status:", debug_test_status)

	health_bar.set_target(self )


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not debug_status_vfx_test:
		return
	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_BRACKETRIGHT:
		apply_status(debug_test_status, 1)
		print("Added status stack:", debug_test_status, " -> ", status_effects.get(debug_test_status, 0))
	elif key_event.keycode == KEY_BRACKETLEFT:
		clear_status(debug_test_status)
		print("Cleared status:", debug_test_status)

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

	# Evasive: remove one stack at start of turn
	if status_effects["evasive"] > 0:
		status_effects["evasive"] -= 1
		if status_effects["evasive"] == 0:
			emit_signal("status_expired", "evasive")

	# Apply start-of-turn effects
	_apply_burn()
	_apply_heal()

	# Reset block each turn
	status_effects["block"] = 0

func end_turn():
	# Empower: remove one stack at end of turn
	if status_effects["empower"] > 0:
		status_effects["empower"] -= 1
		if status_effects["empower"] == 0:
			emit_signal("status_expired", "empower")
	_clear_temp_stats()


func _clear_temp_stats():
	temp_health_mod = 0


# ---------------------------------------------------------
# AI
# ---------------------------------------------------------

# Used for intent
func prepare_next_move():
	if resource == null or resource.moves.is_empty():
		current_move = null
		return
	
	current_move = select_move()


func get_next_move() -> MoveResource:
	if current_move == null:
		return
	
	return current_move


#pick a random move (weighted)
func select_move() -> MoveResource:
	if resource == null or resource.moves.is_empty():
		return null
	
	# In case enemy has only one move
	if resource.moves.size() == 1:
		return resource.moves[0]
	
	var attempts := 0
	
	while attempts < 5:
		var total_weight = 0
		for m in resource.moves:
			total_weight += m.weight
		
		var roll = randi() % total_weight
		var chosen: MoveResource = null
		
		for m in resource.moves:
			roll -= m.weight
			if roll < 0:
				chosen = m
				break
		
		# Prevent repeating the same move too many times
		if chosen == last_move and repeat_count >= 2:
			attempts += 1
			continue
		
		return chosen
	
	return resource.moves[0] # fallback

# ---------------------------------------------------------
# DAMAGE & DEFENSE
# ---------------------------------------------------------

func deal_damage(amount: int = 0, _element: String = "", include_base_damage: bool = true) -> int:
	var dmg = amount
	if include_base_damage:
		dmg += base_damage
	# Empower: +3 damage per stack
	if status_effects["empower"] > 0:
		dmg += 3 * status_effects["empower"]
	
	# Rage: +1 damage per stack
	if status_effects["rage"] > 0:
		dmg += status_effects["rage"]

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

	return dmg

func take_damage(amount: int, _element: String = ""):
	# Evasive: dodge next attack, remove a stack
	if status_effects["evasive"] > 0:
		status_effects["evasive"] -= 1
		emit_signal("status_applied", "evasive", status_effects["evasive"])
		if status_effects["evasive"] == 0:
			emit_signal("status_expired", "evasive")
		return

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
	# Clamp Burn to max 99 stacks
	if status_name == "burn":
		status_effects[status_name] = clamp(status_effects[status_name], 0, 99)
	# Clamp Evasive to max 2
	if status_name == "evasive":
		status_effects[status_name] = clamp(status_effects[status_name], 0, 2)
	
	if status_name == "shock":
		RunManager.player.add_energy(1)
	
	emit_signal("status_applied", status_name, status_effects[status_name])


func clear_status(status_name: String):
	if status_effects[status_name] > 0:
		status_effects[status_name] = 0
		emit_signal("status_expired", status_name)


# ---------------------------------------------------------
# STATUS EFFECT LOGIC
# ---------------------------------------------------------

func modify_stat_temp(_stat_name: String, _amount: int):
	pass


func add_block(amount: int):
	status_effects["block"] += amount


func _apply_burn():
	if status_effects["burn"] > 0:
		# If Overheat Passive is in play
		if RunManager.player.active_passives.has("Overheat"):
			if status_effects["burn"] > 6:
				take_damage(status_effects["burn"] * 2)
			else:
				take_damage(status_effects["burn"] * 1.5)
		else:
			take_damage(status_effects["burn"])
		
		# Decrease by 1
		status_effects["burn"] -= 1
		if status_effects["burn"] == 0:
			emit_signal("status_expired", "burn")


func _apply_heal():
	if status_effects["regeneration"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["regeneration"])
		emit_signal("health_changed", current_health)


func _apply_shock():
	if status_effects["shock"] > 0:
		# Shock deals damage when attacking
		take_damage(status_effects["shock"])
		
		# Decrease by 1
		status_effects["shock"] -= 1
		if status_effects["shock"] == 0:
			emit_signal("status_expired", "shock")


# ---------------------------------------------------------
# UTILITY
# ---------------------------------------------------------

func is_stunned() -> bool:
	return status_effects["stun"] > 0


func try_dodge() -> bool:
	# Evasive is now deterministic and handled in take_damage
	return false


func _die():
	emit_signal("died")
