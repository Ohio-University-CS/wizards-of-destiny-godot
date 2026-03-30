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
@export var debug_test_status: String = "burn"
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
var _status_vfx_root: Node2D
var _status_vfx_nodes := {}

var status_effects := {
	"burn": 0, # take fire damage per completed turn
	"regeneration": 0, # regain hp
	"block": 0, # decreases damage taken
	"freeze": 0, # reduce outgoing damage
	"corroded": 0, # increases incoming damage
	"shock": 0, # deals damage when attacking
	"stun": 0, # skips turn
	"empower": 0, # deal +3 damage per stack, remove 1 at end of turn
	"evasive": 0 # dodge next attack, remove a stack (max 2), remove at start of turn
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

	_status_vfx_root = Node2D.new()
	_status_vfx_root.name = "StatusVFX"
	add_child(_status_vfx_root)

	status_applied.connect(_on_status_applied)
	status_expired.connect(_on_status_expired)

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
		print("Enemy dodged the attack with Evasive!")
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


# ---------------------------------------------------------
# VFX
# ---------------------------------------------------------

func _on_status_applied(status_name: String, stacks: int) -> void:
	match status_name:
		"burn":
			_set_burn_vfx(stacks)
		"regeneration":
			_set_regeneration_vfx(stacks)
		"block":
			_set_block_vfx(stacks)
		"evasive":
			_set_evasive_vfx(stacks)
		"freeze":
			_set_freeze_vfx(stacks)
		"corroded":
			_set_corroded_vfx(stacks)
		"shock":
			_set_shock_vfx(stacks)
		"stun":
			_set_stun_vfx(stacks)


func _on_status_expired(status_name: String) -> void:
	if _status_vfx_nodes.has(status_name):
		var node = _status_vfx_nodes[status_name]
		if is_instance_valid(node):
			node.queue_free()
		_status_vfx_nodes.erase(status_name)


func _set_burn_vfx(stacks: int) -> void:
	if stacks <= 0:
		_on_status_expired("burn")
		return

	var burn_particles: GPUParticles2D = null
	if _status_vfx_nodes.has("burn"):
		burn_particles = _status_vfx_nodes["burn"] as GPUParticles2D
	else:
		burn_particles = _create_burn_particles()
		_status_vfx_root.add_child(burn_particles)
		_status_vfx_nodes["burn"] = burn_particles

	# Scale intensity based on burn stacks.
	burn_particles.amount = clampi(14 + stacks * 6, 14, 64)
	burn_particles.scale = Vector2.ONE * min(1.0 + 0.08 * float(stacks), 1.8)
	burn_particles.emitting = true


func _create_burn_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "BurnParticles"
	particles.position = Vector2(25, 90)
	particles.amount = 5
	particles.lifetime = 0.8
	particles.preprocess = 0.6
	particles.explosiveness = 0.0
	particles.randomness = 1
	particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 100.0
	material.initial_velocity_min = 10
	material.initial_velocity_max = 20
	material.gravity = Vector3(0.0, -10.0, 0.0)
	material.scale_min = 1
	material.scale_max = 5
	
	# Emit from a horizontal line along x-axis for wider fire spread
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(40.0, 1.0, 0.1) # Wide on x-axis for random horizontal emission

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.95, 0.35, 0.95))
	gradient.add_point(0.35, Color(1.0, 0.4, 0.1, 0.8))
	gradient.add_point(1.0, Color(0.4, 0.05, 0.0, 0.0))

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp

	particles.process_material = material
	
	# Load custom burn texture if available and set it on the particle node
	var burn_texture = _load_status_texture("burn")
	if burn_texture:
		particles.texture = burn_texture
	
	return particles

func _set_regeneration_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"regeneration",
		stacks,
		Color(0.35, 1.0, 0.45, 0.85),
		Vector2(0, -28),
		20,
		42.0,
		30.0
	)


func _set_block_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"block",
		stacks,
		Color(0.55, 0.75, 1.0, 0.85),
		Vector2(0, -10),
		16,
		24.0,
		220.0
	)


func _set_evasive_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"evasive",
		stacks,
		Color(0.9, 1.0, 1.0, 0.75),
		Vector2(0, -18),
		14,
		20.0,
		340.0
	)


func _set_freeze_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"freeze",
		stacks,
		Color(0.55, 0.9, 1.0, 0.88),
		Vector2(0, -26),
		18,
		30.0,
		40.0
	)


func _set_corroded_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"corroded",
		stacks,
		Color(0.7, 1.0, 0.25, 0.9),
		Vector2(0, -14),
		17,
		34.0,
		70.0
	)


func _set_shock_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"shock",
		stacks,
		Color(1.0, 0.95, 0.45, 0.95),
		Vector2(0, -24),
		12,
		60.0,
		360.0
	)


func _set_stun_vfx(stacks: int) -> void:
	_set_status_particles_vfx(
		"stun",
		stacks,
		Color(1.0, 0.78, 0.3, 0.9),
		Vector2(0, -36),
		10,
		18.0,
		380.0
	)


func _set_status_particles_vfx(
	status_name: String,
	stacks: int,
	base_color: Color,
	offset: Vector2,
	base_amount: int,
	upward_speed: float,
	radius: float
) -> void:
	if stacks <= 0:
		_on_status_expired(status_name)
		return

	var particles: GPUParticles2D = null
	if _status_vfx_nodes.has(status_name):
		particles = _status_vfx_nodes[status_name] as GPUParticles2D
	else:
		particles = _create_status_particles(status_name, base_color, offset, upward_speed, radius)
		_status_vfx_root.add_child(particles)
		_status_vfx_nodes[status_name] = particles

	particles.amount = clampi(base_amount + stacks * 3, base_amount, 64)
	particles.scale = Vector2.ONE * min(1.0 + 0.05 * float(stacks), 1.6)
	particles.emitting = true


func _create_status_particles(
	status_name: String,
	base_color: Color,
	offset: Vector2,
	upward_speed: float,
	radius: float
) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "%sParticles" % status_name.capitalize()
	particles.position = offset
	particles.amount = 18
	particles.lifetime = 0.9
	particles.preprocess = 0.4
	particles.randomness = 0.8
	particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 40.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius
	material.initial_velocity_min = upward_speed * 0.5
	material.initial_velocity_max = upward_speed
	material.gravity = Vector3(0.0, -12.0, 0.0)
	material.scale_min = 0.2
	material.scale_max = 0.65

	var gradient := Gradient.new()
	gradient.add_point(0.0, base_color)
	gradient.add_point(1.0, Color(base_color.r, base_color.g, base_color.b, 0.0))

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp

	particles.process_material = material
	
	# Load custom texture if it exists for this status and set it on the particle node
	var texture = _load_status_texture(status_name)
	if texture:
		particles.texture = texture
	
	return particles


func _load_status_texture(status_name: String) -> Texture2D:
	# For example: res://art_drop/status effects/burn.png for "burn" status
	var texture_path = "res://art_drop/status effects/%s.png" % status_name
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path) as Texture2D
		if texture:
			print("[StatusVFX] Loaded texture for %s from %s" % [status_name, texture_path])
			return texture
		else:
			print("[StatusVFX] Failed to load texture at %s" % texture_path)
	else:
		print("[StatusVFX] Texture path does not exist: %s" % texture_path)
	return null # No custom texture found, use default coloring
