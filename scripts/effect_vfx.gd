# Handles status effect VFX for any node (enemy or player)
# Usage: Create as a child node and call setup(parent) or auto-connect to parent's signals

extends Node2D
class_name StatusVFXHandler

var parent_node: Node = null
var _status_vfx_nodes := {}
var _is_player: bool = false
var _vfx_on: bool = true
var _status_symbol_area: Node2D = null
var _status_symbol_order: Array[String] = []
var _status_more_dots: Label = null
var _current_status_symbol_key: String = ""
var _status_hover_revealed: bool = false

const _STATUS_SYMBOLS := ["burn", "regeneration", "block", "evasive", "freeze", "corroded", "shock", "stun"]
const _STATUS_SYMBOL_SPACING: float = 20.0
const _STATUS_HOVER_PADDING: float = 8.0
const _STATUS_SYMBOL_TARGET_SIZE: Vector2 = Vector2(24.0, 24.0)

# ---------------------------------------------------------
# INITIALIZATION
# ---------------------------------------------------------

func _ready():
	# Auto-connect to parent if it has the signals
	if parent_node == null:
		parent_node = get_parent()
	_refresh_parent_identity()
	
	_connect_to_parent()
	set_process(true)


func _connect_to_parent() -> void:
	if parent_node == null:
		return
	
	# Check if parent has the signals and connect
	if parent_node.has_signal("status_applied"):
		parent_node.status_applied.connect(_on_status_applied)
	
	if parent_node.has_signal("status_expired"):
		parent_node.status_expired.connect(_on_status_expired)


func setup(parent: Node) -> void:
	"""Manually set parent and connect signals"""
	parent_node = parent
	_refresh_parent_identity()
	_connect_to_parent()


func _refresh_parent_identity() -> void:
	if parent_node == null:
		_is_player = false
		return

	# Use multiple checks so player detection works even if class typing is inconsistent.
	var script_path: String = ""
	var script_ref: Script = parent_node.get_script() as Script
	if script_ref != null:
		script_path = script_ref.resource_path.to_lower()

	_is_player = parent_node is Player or parent_node.name.to_lower() == "player" or script_path.ends_with("player.gd")


func _get_scale_direction() -> float:
	"""Get the X scale direction of parent. Returns 1.0 or -1.0"""
	if parent_node == null:
		return 1.0
	
	# Check if parent is a Player class - if so, invert the X axis
	if _is_player:
		return -1.0
	
	# For enemies and other entities, check actual scale
	var parent_scale = parent_node.scale.x
	return 1.0 if parent_scale >= 0 else -1.0


func _apply_scale_to_offset(offset: Vector2) -> Vector2:
	"""Apply parent's scale direction to X offset for universal positioning"""
	var scale_dir = _get_scale_direction()
	return Vector2(offset.x * scale_dir, offset.y)


# ---------------------------------------------------------
# SIGNAL HANDLERS
# ---------------------------------------------------------

func _on_status_applied(status_name: String, stacks: int) -> void:
	if stacks > 0:
		_spawn_status_symbol(status_name)

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
	# Clean up any associated behind sprite.
	var sprite_key := status_name + "_sprite"
	if _status_vfx_nodes.has(sprite_key):
		var sprite_node = _status_vfx_nodes[sprite_key]
		if is_instance_valid(sprite_node):
			sprite_node.queue_free()
		_status_vfx_nodes.erase(sprite_key)
		_status_symbol_order.erase(sprite_key)
		_layout_status_symbols()


# ---------------------------------------------------------
# VFX IMPLEMENTATIONS
# ---------------------------------------------------------

func _set_burn_vfx(stacks: int) -> void: # burn could be tinkered with
	if stacks <= 0:
		_on_status_expired("burn")
		return

	var burn_particles: GPUParticles2D = null
	if _status_vfx_nodes.has("burn"):
		burn_particles = _status_vfx_nodes["burn"] as GPUParticles2D
	else:
		burn_particles = _create_burn_particles()
		add_child(burn_particles)
		_status_vfx_nodes["burn"] = burn_particles

	# Scale intensity based on burn stacks.
	burn_particles.amount = clampi(6 + stacks * 2, 6, 10)
	burn_particles.scale = Vector2.ONE * min(1.0 + 0.08 * float(stacks), 1.8)
	burn_particles.emitting = true


func _create_burn_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = "BurnParticles"
	particles.position = _apply_scale_to_offset(Vector2(25, 70))
	particles.amount = 4
	particles.lifetime = 1.4
	particles.preprocess = 0.6
	particles.explosiveness = 0.0
	particles.randomness = 1
	particles.emitting = true

	var particle_material := ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 75.0
	particle_material.initial_velocity_min = 5
	particle_material.initial_velocity_max = 15
	particle_material.gravity = Vector3(0.0, -10.0, 0.0)
	particle_material.scale_min = 1
	particle_material.scale_max = 5
	
	# Emit from a horizontal line along x-axis for wider fire spread
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(30.0, 1.0, 0.1) # Wide on x-axis for random horizontal emission
 
	particles.process_material = particle_material
	
	# Load custom burn texture if available and set it on the particle node
	var burn_texture = _load_status_texture("burn")
	if burn_texture:
		particles.texture = burn_texture
	
	return particles


func _set_regeneration_vfx(stacks: int) -> void: # done
	_set_status_particles_vfx(
		"regeneration",
		stacks,
		Color(0.35, 1.0, 0.45, 0.85),
		Vector2(25, 70),
		20,
		20.0,
		20.0
	)
	if _is_player:
		var staff_particles = _create_staff_status_particles("regeneration", Color(0.35, 1.0, 0.45, 0.85), Vector2(-40, -50), 20.0, 24.0)
		add_child(staff_particles)


func _set_block_vfx(stacks: int) -> void:
	if stacks <= 0:
		_on_status_expired("block")
		return

	var block_sprite: Sprite2D = null
	if _status_vfx_nodes.has("block"):
		block_sprite = _status_vfx_nodes["block"] as Sprite2D
	else:
		block_sprite = _create_block_vfx()
		if block_sprite == null:
			return
		add_child(block_sprite)
		_status_vfx_nodes["block"] = block_sprite
		_start_block_glisten(block_sprite)

	# Slightly scale with stacks so bigger block values feel more present.
	block_sprite.position = _apply_scale_to_offset(Vector2(40, 50))
	block_sprite.scale = Vector2.ONE * 3.0


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
		add_child(particles)
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
	particles.position = _apply_scale_to_offset(offset)
	particles.amount = 5
	particles.lifetime = 0.9
	particles.preprocess = 0.4
	particles.randomness = 0.8
	particles.emitting = true

	var particle_material := ParticleProcessMaterial.new() # small particles
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 55.0
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(radius * 1.25, radius * .75, 0.1)
	particle_material.initial_velocity_min = upward_speed * 0.5
	particle_material.initial_velocity_max = upward_speed
	particle_material.gravity = Vector3(0.0, -10.0, 0.0)
	particle_material.scale_min = 0.2
	particle_material.scale_max = 0.65

	var gradient := Gradient.new()
	gradient.add_point(0.0, base_color)
	gradient.add_point(1.0, Color(base_color.r, base_color.g, base_color.b, 0.0))

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	particle_material.color_ramp = ramp

	particles.process_material = particle_material
	
	# Load custom texture if it exists for this status and set it on the particle node
	var texture = _load_status_texture(status_name)
	if texture:
		particles.texture = texture
	
	return particles


func _create_staff_status_particles(
	status_name: String,
	base_color: Color,
	offset: Vector2,
	upward_speed: float,
	radius: float
) -> GPUParticles2D:
	"""Similar to _create_status_particles but optimized for staff visuals"""
	var particles := GPUParticles2D.new()
	particles.name = "%sStaffParticles" % status_name.capitalize()
	particles.position = _apply_scale_to_offset(offset)
	particles.amount = 4
	particles.lifetime = 0.9
	particles.preprocess = 0.4
	particles.randomness = 0.8
	particles.emitting = true

	var particle_material := ParticleProcessMaterial.new() # small particles
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 35.0
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_box_extents = Vector3(radius * 2, radius, 0.1)
	particle_material.emission_sphere_radius = radius
	particle_material.initial_velocity_min = upward_speed * 0.5
	particle_material.initial_velocity_max = upward_speed
	particle_material.gravity = Vector3(0.0, -10.0, 0.0)
	particle_material.scale_min = 0.2
	particle_material.scale_max = 0.65

	var gradient := Gradient.new()
	gradient.add_point(0.0, base_color)
	gradient.add_point(1.0, Color(base_color.r, base_color.g, base_color.b, 0.0))

	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	particle_material.color_ramp = ramp

	particles.process_material = particle_material
	
	# Load custom texture if it exists for this status and set it on the particle node
	var texture = _load_status_texture(status_name)
	if texture:
		particles.texture = texture
	
	return particles

func _create_block_vfx() -> Sprite2D:
	var texture := _load_status_texture("block")
	if texture == null:
		return null

	var sprite := Sprite2D.new()
	sprite.name = "BlockSprite"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _apply_scale_to_offset(Vector2(0, -14))
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.9)
	return sprite


func _start_block_glisten(block_sprite: Sprite2D) -> void:
	if not is_instance_valid(block_sprite):
		return

	# Trigger a diagonal glint sweep at random intervals while block is active.
	var delay: float = randf_range(1.2, 4.0)
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(block_sprite):
			return
		_start_block_glisten(block_sprite)
	)

func _spawn_status_symbol(status_name: String) -> void:
	if status_name not in _STATUS_SYMBOLS:
		return

	var texture: Texture2D = _load_status_texture(status_name)
	if texture == null:
		return

	if _status_symbol_area == null or not is_instance_valid(_status_symbol_area):
		_status_symbol_area = Node2D.new()
		_status_symbol_area.name = "StatusSymbolArea"
		_status_symbol_area.z_as_relative = false
		_status_symbol_area.z_index = 5000
		if _is_player:
			var ui_stack: Node2D = _get_player_ui_status_stack()
			if ui_stack != null:
				ui_stack.add_child(_status_symbol_area)
				_status_symbol_area.position = Vector2.ZERO
			else:
				add_child(_status_symbol_area)
		else:
			add_child(_status_symbol_area)
		_ensure_status_stack_ui_nodes()

	_status_symbol_area.position = _get_status_symbol_anchor()

	var sprite_key: String = status_name + "_sprite"
	_current_status_symbol_key = sprite_key
	if _status_vfx_nodes.has(sprite_key):
		var existing_sprite: Sprite2D = _status_vfx_nodes[sprite_key] as Sprite2D
		if is_instance_valid(existing_sprite):
			existing_sprite.texture = texture
			_apply_uniform_status_symbol_scale(existing_sprite)
			_layout_status_symbols()
			return
		_status_vfx_nodes.erase(sprite_key)
		_status_symbol_order.erase(sprite_key)

	var status_symbol := Sprite2D.new()
	status_symbol.name = "%sSymbol" % status_name.capitalize()
	status_symbol.texture = texture
	status_symbol.centered = true
	_apply_uniform_status_symbol_scale(status_symbol)

	_status_symbol_area.add_child(status_symbol)
	_status_vfx_nodes[sprite_key] = status_symbol
	if sprite_key not in _status_symbol_order:
		_status_symbol_order.push_back(sprite_key)
	_layout_status_symbols()


func _process(_delta: float) -> void:
	_update_status_hover_state()


func _update_status_hover_state() -> void:
	var hovered_now: bool = _is_current_status_hovered()
	if hovered_now != _status_hover_revealed:
		_status_hover_revealed = hovered_now
		_layout_status_symbols()


func _is_current_status_hovered() -> bool:
	if _status_symbol_area == null or not is_instance_valid(_status_symbol_area):
		return false
	if _current_status_symbol_key == "" or not _status_vfx_nodes.has(_current_status_symbol_key):
		return false

	var current_symbol: Sprite2D = _status_vfx_nodes[_current_status_symbol_key] as Sprite2D
	if not is_instance_valid(current_symbol) or not current_symbol.visible:
		return false
	if current_symbol.texture == null:
		return false

	var mouse_global: Vector2 = get_global_mouse_position()
	var symbol_size: Vector2 = current_symbol.texture.get_size() * current_symbol.global_scale
	var half_size: Vector2 = symbol_size * 0.5
	var pad: Vector2 = Vector2.ONE * _STATUS_HOVER_PADDING
	var rect: Rect2 = Rect2(current_symbol.global_position - half_size - pad, symbol_size + pad * 2.0)
	return rect.has_point(mouse_global)


func _ensure_status_stack_ui_nodes() -> void:
	if _status_symbol_area == null or not is_instance_valid(_status_symbol_area):
		return
	if _status_more_dots != null and is_instance_valid(_status_more_dots):
		return

	_status_more_dots = Label.new()
	_status_more_dots.name = "MoreStatusDots"
	_status_more_dots.text = "..."
	_status_more_dots.visible = false
	_status_more_dots.position = Vector2(14, -14)
	_status_symbol_area.add_child(_status_more_dots)


func _layout_status_symbols() -> void:
	if _status_symbol_area == null or not is_instance_valid(_status_symbol_area):
		return
	_ensure_status_stack_ui_nodes()

	_status_symbol_area.position = _get_status_symbol_anchor()

	var active_queue: Array[String] = []
	for sprite_key in _status_symbol_order:
		if _status_vfx_nodes.has(sprite_key):
			var symbol: Sprite2D = _status_vfx_nodes[sprite_key] as Sprite2D
			if is_instance_valid(symbol):
				active_queue.push_back(sprite_key)

	if active_queue.size() == 0:
		if _status_more_dots != null and is_instance_valid(_status_more_dots):
			_status_more_dots.visible = false
		_current_status_symbol_key = ""
		return

	if _current_status_symbol_key == "" or not active_queue.has(_current_status_symbol_key):
		_current_status_symbol_key = str(active_queue[active_queue.size() - 1])

	var ordered_keys: Array[String] = []
	ordered_keys.push_back(_current_status_symbol_key)
	for i in range(active_queue.size() - 1, -1, -1):
		var key: String = str(active_queue[i])
		if key != _current_status_symbol_key:
			ordered_keys.push_back(key)

	var collapsed: bool = active_queue.size() > 1 and not _status_hover_revealed
	var x_dir: float = -1.0 if _is_player else 1.0

	for i in range(ordered_keys.size()):
		var key: String = ordered_keys[i]
		var symbol: Sprite2D = _status_vfx_nodes[key] as Sprite2D
		if not is_instance_valid(symbol):
			continue

		if collapsed and i > 0:
			symbol.visible = false
		else:
			symbol.visible = true
			symbol.position = Vector2(float(i) * _STATUS_SYMBOL_SPACING * x_dir, 0.0)

	if _status_more_dots != null and is_instance_valid(_status_more_dots):
		_status_more_dots.visible = active_queue.size() > 1 and collapsed
		var dots_pos := Vector2(10.0 * x_dir, 10.0)
		var current_symbol: Sprite2D = _status_vfx_nodes[_current_status_symbol_key] as Sprite2D
		if is_instance_valid(current_symbol) and current_symbol.texture != null:
			var half_size: Vector2 = current_symbol.texture.get_size() * current_symbol.scale * 0.5
			dots_pos = current_symbol.position + Vector2(half_size.x * x_dir - 6.0 * x_dir, half_size.y - 15.0)
		_status_more_dots.position = dots_pos


func _apply_uniform_status_symbol_scale(symbol: Sprite2D) -> void:
	if symbol == null or symbol.texture == null:
		return

	var texture_size: Vector2 = symbol.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale_x: float = _STATUS_SYMBOL_TARGET_SIZE.x / texture_size.x
	var scale_y: float = _STATUS_SYMBOL_TARGET_SIZE.y / texture_size.y
	var uniform_scale: float = minf(scale_x, scale_y)
	symbol.scale = Vector2.ONE * uniform_scale


func _get_status_symbol_anchor() -> Vector2:
	if _is_player:
		var ui_stack: Node2D = _get_player_ui_status_stack()
		if ui_stack != null:
			return Vector2.ZERO

	if parent_node != null:
		var status_stack: Node2D = parent_node.get_node_or_null("StatusStack") as Node2D
		if status_stack != null:
			return status_stack.position

	return Vector2(-120, -110) if _is_player else Vector2(56, -40)


func _get_player_ui_status_stack() -> Node2D:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.find_child("PlayerStatusStack", true, false) as Node2D
	
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
