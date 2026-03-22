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


func setup_from_resource(res: EnemyResource) -> void:
	resource = res
	base_max_health = res.hp_variation[0]
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
	"evasive": 0, # 25% chance to dodge per stack (base max 2)
	"freeze": 0, # reduce outgoing damage
	"corroded": 0, # increases incoming damage
	"shock": 0, # deals damage when attacking
	"stun": 0 # skips turn
}

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
	
	health_bar.set_target(self)

# ---------------------------------------------------------
# COMBAT INTERFACE
# ---------------------------------------------------------

func start_turn():
	# Apply start-of-turn effects
	_apply_heal()
	_apply_shock()

	# Reset block each turn
	status_effects["block"] = 0

func end_turn():
	_apply_burn()
	_clear_temp_stats()


func _clear_temp_stats():
	temp_health_mod = 0


# ---------------------------------------------------------
# AI
# ---------------------------------------------------------

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

	# Apply outgoing modifiers here if desired
	# Freeze reduces outgoing damage by 10% per stack
	if status_effects.has("freeze"):
		var freeze_stacks = status_effects["freeze"]
		if freeze_stacks > 0:
			var multiplier = 1.0 - (0.1 * freeze_stacks)
			multiplier = max(multiplier, 0.4)
			dmg = int(dmg * multiplier)
	return dmg

func take_damage(amount: int, _element: String = ""):
	if try_dodge():
		return
	
	var dmg = amount
	
	# Freeze reduces outgoing damage, not incoming
	# Poison increases incoming damage, stacks
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
	
	print("Player deals ", dmg, " to Enemy")
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
		take_damage(status_effects["burn"])
		status_effects["burn"] -= 1


func _apply_heal():
	if status_effects["regeneration"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["regeneration"])
		emit_signal("health_changed", current_health)


func _apply_shock():
	if status_effects["shock"] > 0:
		# Shock reduces energy
		pass


# ---------------------------------------------------------
# UTILITY
# ---------------------------------------------------------

func is_stunned() -> bool:
	return status_effects["stun"] > 0


func try_dodge() -> bool:
	if status_effects["evasive"] > 0:
		var chance = 0.25 * status_effects["evasive"]
		return randf() < chance
	return false


func _die():
	emit_signal("died")
