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
		if status_effects["burn"] <= 0:
			emit_signal("status_expired", "burn")


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

	# Also free auxiliary VFX nodes (e.g., background sprite, embers)
	var back_key = "%s_back" % status_name
	if _status_vfx_nodes.has(back_key):
		var back_node = _status_vfx_nodes[back_key]
		if is_instance_valid(back_node):
			back_node.queue_free()
		_status_vfx_nodes.erase(back_key)

	var ember_key = "%s_embers" % status_name
	if _status_vfx_nodes.has(ember_key):
		var ember_node = _status_vfx_nodes[ember_key]
		if is_instance_valid(ember_node):
			ember_node.queue_free()
		_status_vfx_nodes.erase(ember_key)

	var ember_inv_key = "%s_embers_inverted" % status_name
	if _status_vfx_nodes.has(ember_inv_key):
		var ember_inv_node = _status_vfx_nodes[ember_inv_key]
		if is_instance_valid(ember_inv_node):
			ember_inv_node.queue_free()
		_status_vfx_nodes.erase(ember_inv_key)

	var small_key = "%s_small" % status_name
	if _status_vfx_nodes.has(small_key):
		var small_node = _status_vfx_nodes[small_key]
		if is_instance_valid(small_node):
			small_node.queue_free()
		_status_vfx_nodes.erase(small_key)

	var pixel_key = "%s_pixel_embers" % status_name
	if _status_vfx_nodes.has(pixel_key):
		var pixel_node = _status_vfx_nodes[pixel_key]
		if is_instance_valid(pixel_node):
			pixel_node.queue_free()
		_status_vfx_nodes.erase(pixel_key)


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
	burn_particles.amount = clampi(10, 5, 10)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var variance := rng.randf_range(-0.04, 0.12)
	var target_scale := 1.0 + 0.08 * float(stacks) + variance
	target_scale = clamp(target_scale, 0.9, 1.2)
	burn_particles.scale = Vector2.ONE * target_scale
	burn_particles.emitting = true


func _create_burn_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "BurnParticles"
	particles.position = Vector2(25, 70)
	# Increase base amount so particles can fill the box when spread wide
	particles.amount = 10
	particles.lifetime = 1.5
	particles.preprocess = 0.6
	particles.explosiveness = 0.0
	particles.randomness = .5
	particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 100.0
	material.initial_velocity_min = 10
	material.initial_velocity_max = 20
	material.gravity = Vector3(0.0, -10.0, 0.0)
	material.scale_min = 1
	material.scale_max = 5

	# Shrink main burn particles over their lifetime (scale curve: 1 -> 0)
	var burn_scale_curve := Curve.new()
	burn_scale_curve.add_point(Vector2(0.0, 1.0))
	burn_scale_curve.add_point(Vector2(1.0, 0.0))
	var burn_scale_tex := CurveTexture.new()
	burn_scale_tex.curve = burn_scale_curve
	material.scale_curve = burn_scale_tex

	# Emit from a horizontal box: narrow vertical band (shorter spawn height)
	# and wide horizontal extent for stronger X-axis randomness.
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(30.0, 1.0, 0.1) # wide X, short Y

	var gradient := Gradient.new()
	# Fire color ramp: bright core -> orange -> fade to transparent
	gradient.add_point(0.0, Color(1.0, 0.98, 0.6, 1.0))
	gradient.add_point(0.18, Color(1.0, 0.7, 0.18, 0.95))
	gradient.add_point(0.4, Color(1.0, 0.42, 0.12, 0.85))
	# gradient.add_point(0.7, Color(0.7, 0.12, 0.04, 0.6))
	

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp

	particles.process_material = material
	
	# Load custom burn texture if available and set it on the particle node
	var burn_texture = _load_status_texture("burn")
	if burn_texture:
		particles.texture = burn_texture

	# --- Small burn layer: smaller sprites that spawn toward the ends (wide X extents)
	var small_burn := GPUParticles2D.new()
	small_burn.name = "BurnSmall"
	small_burn.position = Vector2(25, 70)
	small_burn.amount = 5
	small_burn.lifetime = 1.1
	small_burn.preprocess = 0.2
	small_burn.explosiveness = 0.0
	small_burn.randomness = 1.0
	small_burn.emitting = true

	var small_mat := ParticleProcessMaterial.new()
	small_mat.direction = Vector3(0.0, -1.0, 0.0)
	small_mat.spread = 120.0
	small_mat.initial_velocity_min = 6
	small_mat.initial_velocity_max = 14
	small_mat.gravity = Vector3(0.0, -8.0, 0.0)
	small_mat.scale_min = 0.5
	small_mat.scale_max = 1

	# Shrink small burn sprites over their lifetime
	var small_scale_curve := Curve.new()
	small_scale_curve.add_point(Vector2(0.0, 1.0))
	small_scale_curve.add_point(Vector2(1.0, 0.0))
	var small_scale_tex := CurveTexture.new()
	small_scale_tex.curve = small_scale_curve
	small_mat.scale_curve = small_scale_tex
	# Wide box so small burns spawn more toward the ends of the emission area
	small_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	small_mat.emission_box_extents = Vector3(72.0, 1.0, 0.1)

	# Use a slightly subdued ramp so small burns read as smaller embers
	var small_grad := Gradient.new()
	small_grad.add_point(0.0, Color(1.0, 0.85, 0.4, 1.0))
	small_grad.add_point(0.5, Color(1.0, 0.45, 0.12, 0.85))
	# small burn fades color to grey but keeps alpha; shrink removes them
	small_grad.add_point(1.0, Color(0.25, 0.25, 0.25, 1.0))
	var small_ramp := GradientTexture1D.new()
	small_ramp.gradient = small_grad
	small_mat.color_ramp = small_ramp

	small_burn.process_material = small_mat
	if burn_texture:
		small_burn.texture = burn_texture

	# Add small burn layer as a sibling under the VFX root and track it
	if is_instance_valid(_status_vfx_root):
		_status_vfx_root.add_child(small_burn)
		_status_vfx_nodes["burn_small"] = small_burn

	# --- Pixel embers: small 1x1 white texture tinted by ramp -> orange/yellow to grey ---
	var pixel_embers := GPUParticles2D.new()
	pixel_embers.name = "PixelEmbers"
	pixel_embers.position = Vector2(0, 0)
	pixel_embers.amount = 28
	pixel_embers.lifetime = 0.9
	pixel_embers.preprocess = 0.0
	pixel_embers.randomness = 1.0
	pixel_embers.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0.0, -1.0, 0.0)
	pmat.spread = 50.0
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(72.0, 2.0, 0.1)
	pmat.initial_velocity_min = 6
	pmat.initial_velocity_max = 14
	pmat.gravity = Vector3(0.0, -6.0, 0.0)
	pmat.scale_min = 0.06
	pmat.scale_max = 0.18

	# Pixel embers shrink to 0 scale over lifetime
	var pscale := Curve.new()
	pscale.add_point(Vector2(0.0, 1.0))
	pscale.add_point(Vector2(1.0, 0.0))
	var p_scale_tex := CurveTexture.new()
	p_scale_tex.curve = pscale
	pmat.scale_curve = p_scale_tex

	var pgrad := Gradient.new()
	pgrad.add_point(0.0, Color(1.0, 0.9, 0.3, 1.0)) # yellowish start
	pgrad.add_point(0.35, Color(1.0, 0.55, 0.12, 1.0)) # orange mid
	pgrad.add_point(0.8, Color(0.35, 0.35, 0.35, 0.9)) # grey near end
	# keep alpha, let scale curve shrink pixels away
	pgrad.add_point(1.0, Color(0.2, 0.2, 0.2, 1.0)) # grey at end (alpha kept)

	var pramp := GradientTexture1D.new()
	pramp.gradient = pgrad
	pmat.color_ramp = pramp

	pixel_embers.process_material = pmat

	# create a 1x1 white pixel texture so ramp controls color
	var px_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	px_img.set_pixel(0, 0, Color(1, 1, 1, 1))
	var px_tex := ImageTexture.create_from_image(px_img)
	pixel_embers.texture = px_tex

	if is_instance_valid(_status_vfx_root):
		_status_vfx_root.add_child(pixel_embers)
		_status_vfx_nodes["burn_pixel_embers"] = pixel_embers

	# --- Ember layer (small glowing embers that drift up) ---
	var ember_particles := GPUParticles2D.new()
	ember_particles.name = "Embers"
	ember_particles.position = Vector2(0, 0)
	ember_particles.amount = 12
	ember_particles.lifetime = 3.5
	ember_particles.preprocess = 0.4
	ember_particles.randomness = 0.9
	ember_particles.emitting = true

	var ember_material := ParticleProcessMaterial.new()
	ember_material.direction = Vector3(0.0, -1.0, 0.0)
	ember_material.spread = 60.0
	ember_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ember_material.emission_box_extents = Vector3(48.0, 4.0, 0.1)
	ember_material.initial_velocity_min = 10
	ember_material.initial_velocity_max = 20
	ember_material.gravity = Vector3(0.0, -6.0, 0.0)
	ember_material.scale_min = .5
	ember_material.scale_max = 1

	# Make embers shrink over their lifetime
	var ember_scale_curve := Curve.new()
	ember_scale_curve.add_point(Vector2(0.0, 1.0))
	ember_scale_curve.add_point(Vector2(1.0, 0.0))
	var ember_scale_tex := CurveTexture.new()
	ember_scale_tex.curve = ember_scale_curve
	ember_material.scale_curve = ember_scale_tex

	var ember_grad := Gradient.new()
	ember_grad.add_point(0.0, Color(1.0, 0.95, 0.7, 1.0))
	ember_grad.add_point(0.15, Color(1.0, 0.7, 0.2, 0.95))
	ember_grad.add_point(0.4, Color(1.0, 0.45, 0.12, 0.7))
	ember_grad.add_point(0.75, Color(0.6, 0.18, 0.06, 0.45))
	# End ember ramp in grey and keep alpha; shrinking will make them disappear
	ember_grad.add_point(1.0, Color(0.25, 0.25, 0.25, 1.0))

	var ember_ramp := GradientTexture1D.new()
	ember_ramp.gradient = ember_grad
	ember_material.color_ramp = ember_ramp
	ember_particles.process_material = ember_material

	# prefer a small ember texture if it exists, otherwise create a tiny
	# 2x2 pixel texture where each pixel is a specific ember/smoke color
	var ember_texture = _load_status_texture("ember")
	if not ember_texture:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		# Set pixels directly (Godot 4: Image.lock()/unlock() removed)
		img.set_pixel(0, 0, Color(1.0, 0.12, 0.12, 1.0)) # top-left: red
		img.set_pixel(1, 0, Color(1.0, 0.55, 0.12, 1.0)) # top-right: orange
		img.set_pixel(0, 1, Color(1.0, 0.85, 0.18, 1.0)) # bottom-left: yellow
		img.set_pixel(1, 1, Color(0.15, 0.15, 0.15, 1.0)) # bottom-right: dark grey (smoke)
		var gen_tex := ImageTexture.create_from_image(img)
		ember_texture = gen_tex

	if ember_texture:
		ember_particles.texture = ember_texture
		# Remove color ramp tint so texture pixel colors show accurately
		ember_material.color_ramp = null

	# Add ember layer as a sibling under the VFX root so it renders correctly
	# and can be managed independently.
	_status_vfx_root.add_child(ember_particles)
	_status_vfx_nodes["burn_embers"] = ember_particles

	# --- Inverted ember layer: some embers drift downward for variety ---
	var ember_inv := GPUParticles2D.new()
	ember_inv.name = "EmbersInverted"
	ember_inv.position = ember_particles.position
	ember_inv.amount = max(6, int(ember_particles.amount / 2.0))
	ember_inv.lifetime = ember_particles.lifetime
	ember_inv.preprocess = ember_particles.preprocess
	ember_inv.randomness = ember_particles.randomness
	ember_inv.emitting = true

	# Duplicate the ember material and invert its Y direction so particles fall
	var inv_mat := ember_material.duplicate() as ParticleProcessMaterial
	if inv_mat:
		inv_mat.direction = Vector3(0.0, 1.0, 0.0) # downward
		# Slightly increase spread/velocity variance for visual distinction
		inv_mat.spread = ember_material.spread * 1.1
		inv_mat.initial_velocity_min = ember_material.initial_velocity_min * 0.6
		inv_mat.initial_velocity_max = ember_material.initial_velocity_max * 0.9

	ember_inv.process_material = inv_mat

	if ember_texture:
		ember_inv.texture = ember_texture

	_status_vfx_root.add_child(ember_inv)
	_status_vfx_nodes["burn_embers_inverted"] = ember_inv
	
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

	# Shrink status particles over lifetime instead of fading them out
	var status_scale := Curve.new()
	status_scale.add_point(Vector2(0.0, 1.0))
	status_scale.add_point(Vector2(1.0, 0.0))
	var status_scale_tex := CurveTexture.new()
	status_scale_tex.curve = status_scale
	material.scale_curve = status_scale_tex

	var gradient := Gradient.new()
	gradient.add_point(0.0, base_color)
	# keep alpha so particles remain visible while shrinking to zero scale
	gradient.add_point(1.0, Color(base_color.r, base_color.g, base_color.b, 1.0))

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
