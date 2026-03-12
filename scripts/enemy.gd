extends Node
class_name Enemy

# ---------------------------------------------------------
# ENEMY STATS (Base + Modifiers)
# ---------------------------------------------------------

var resource : EnemyResource = null

# BASE STATS (from class)
var base_max_health: int


var temp_health_mod : int = 0

# Predefined enemy categories with sensible defaults
const CATEGORY_STATS = {
	"Goblin": {
		"max_health": 18
	},
	"Wizard": {
		"max_health": 16
	},
	"Robot": {
		"max_health": 30
	}
}

# Human-friendly category label
@export var category: String = "Goblin"

# Runtime values
var current_health: int


func setup_from_resource(res : EnemyResource) -> void:
	resource = res
	base_max_health = res.base_hp
	current_health = base_max_health


func configure_from_category(cat: String) -> void:
	# Apply presets from CATEGORY_STATS. Falls back to Goblin if missing.
	var stats = CATEGORY_STATS.get(cat, CATEGORY_STATS["Goblin"])

	base_max_health = stats["max_health"]

	current_health = get_max_health()
	category = cat



static func new_enemy(cat: String) -> Enemy:
	var e = Enemy.new()
	e.configure_from_category(cat)
	return e


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

func end_turn():
	_apply_burn()
	_clear_temp_stats()


func _clear_temp_stats():
	temp_health_mod = 0


# ---------------------------------------------------------
# AI
# ---------------------------------------------------------

#pick a random move (weighted)
func select_move() -> MoveResource:
	if resource == null or resource.moves.is_empty():
		return null
	
	var total_weight = 0
	for m in resource.moves:
		total_weight += m.weight
	
	var roll = randi() % total_weight
	for m in resource.moves:
		roll -= m.weight
		if roll < 0:
			return m
	
	return resource.moves[0] #fallback


#perform selected move on target
func perform_move(target : Node) -> void:
	var move = select_move()
	if move == null:
		return
	
	var dmg = move.base_damage
	target.take_damage(dmg)
	
	#Apply status effects from the move
	if move.status_effects:
		for status_name in move.status_effects.keys():
			var stacks = move.status_effects[status_name]
			target.apply_status(status_name, stacks)


# ---------------------------------------------------------
# DAMAGE & DEFENSE
# ---------------------------------------------------------

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

	if current_health <= 0:
		_die()


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
	pass


func add_block(amount: int):
	status_effects["block"] += amount


func _apply_burn():
	if status_effects["burn"] > 0:
		take_damage(status_effects["burn"])


func _apply_heal():
	if status_effects["regeneration"] > 0:
		current_health = min(get_max_health(), current_health + status_effects["heal"])
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
