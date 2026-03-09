extends Panel

signal card_clicked
signal drag_started
signal drag_ended

# Visuals / hover
@export var hover_scale: Vector2 = Vector2(1.08, 1.08)
@export var lerp_speed: float = 10.0

# Size
@export var x_size: float = 150.0
@export var y_size: float = 220.0

# Tilt behavior
@export var max_tilt_angle: float = 15.0
@export var mouse_tilt_amount: float = 6.0
@export var tilt_speed: float = 12.0
@export var return_speed: float = 6.0

# Drag settings
@export var drag_lerp_speed: float = 20.0
@export var vertical_drag_padding: float = 120.0
@export var drag_delay: float = 100.0 # ms before hold turns into drag

var is_hovered: bool = false
var is_dragging: bool = false
var is_pressing: bool = false
var press_start_pos: Vector2 = Vector2.ZERO
var press_time: float = 0.0
var drag_offset: Vector2 = Vector2.ZERO
var target_scale: Vector2 = Vector2.ONE
var last_global_pos: Vector2 = Vector2.ZERO
var current_tilt: float = 0.0

# Placeholder & parenting info for in-HBox dragging
var placeholder: Control = null
var original_parent: Control = null
var original_index: int = -1
var parent_global_rect: Rect2 = Rect2()

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_card_size(x_size, y_size)
	last_global_pos = global_position

func _process(delta: float) -> void:
	# smooth scaling
	scale = scale.lerp(target_scale, lerp_speed * delta)

	# handle press-to-drag delay
	if is_pressing and not is_dragging:
		press_time += delta * 1000.0
		if press_time >= drag_delay:
			_start_drag()

	# movement velocity for movement-tilt
	var move_velocity = global_position.x - last_global_pos.x
	last_global_pos = global_position
	var movement_target = clamp(move_velocity * 0.6, -max_tilt_angle, max_tilt_angle)

	# mouse offset tilt
	var mouse_target := 0.0
	if is_dragging:
		# follow mouse while dragging freely across the screen
		var target_pos = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_pos, drag_lerp_speed * delta)

	if is_hovered and not is_dragging:
		var local_m = get_local_mouse_position()
		var center_offset = 0.0
		if size.x != 0:
			center_offset = (local_m.x - (size.x * 0.5)) / (size.x * 0.5)
		mouse_target = center_offset * mouse_tilt_amount

	# combine tilt and apply
	var final_target = movement_target + mouse_target
	if abs(move_velocity) > 0.1 or is_hovered:
		current_tilt = lerp(current_tilt, final_target, tilt_speed * delta)
	else:
		current_tilt = lerp(current_tilt, 0.0, return_speed * delta)
	rotation = deg_to_rad(current_tilt)

func set_card_size(new_x: float, new_y: float) -> void:
	custom_minimum_size = Vector2(new_x, new_y)
	size = Vector2(new_x, new_y)
	pivot_offset = size * 0.5

func _on_mouse_entered() -> void:
	is_hovered = true
	target_scale = hover_scale
	z_index = 20
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	# just use z_index for hover visual priority, no top_level needed

func _on_mouse_exited() -> void:
	is_hovered = false
	target_scale = Vector2.ONE
	z_index = 0
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	# no top_level changes needed for hover exit

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# begin press (click action immediate), but delay entering drag state
			is_pressing = true
			press_time = 0.0
			press_start_pos = get_global_mouse_position()
			drag_offset = press_start_pos - global_position
			emit_signal("card_clicked")
		else:
			# release: stop pressing and if currently dragging, start return
			is_pressing = false
			if is_dragging:
				is_dragging = false
				emit_signal("drag_ended")
				_end_drag()

func _unhandled_input(event) -> void:
	# ensure we stop dragging if mouse release is missed by _gui_input (due to reparenting)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_dragging:
			is_dragging = false
			_end_drag()
		if is_pressing:
			is_pressing = false

func _start_drag() -> void:
	# record original parent + index
	original_parent = get_parent() as Control
	if not original_parent:
		return
	original_index = original_parent.get_children().find(self )
	# create placeholder (invisible) to keep HBox layout
	placeholder = Control.new()
	placeholder.custom_minimum_size = size
	placeholder.name = "CardPlaceholder_%s" % str(get_instance_id())
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	original_parent.add_child(placeholder)
	original_parent.move_child(placeholder, original_index)
	# capture original global position so we can return to this slot
	var gp = global_position
	# reparent to the scene root so drag is free across screen
	var tree = get_tree()
	if tree and tree.get_root():
		original_parent.remove_child(self )
		request_ready()
		tree.get_root().add_child(self )
		global_position = gp
		_set_top_level_preserve(true)
		z_index = 100
	else:
		# fallback: keep under original parent but still mark drag
		_set_top_level_preserve(true)
		z_index = 100

	is_dragging = true
	press_time = 0.0
	emit_signal("drag_started")

func _end_drag() -> void:
	# if no parent info, just reset visuals
	if not original_parent:
		target_scale = Vector2.ONE
		scale = Vector2.ONE
		_set_top_level_preserve(false)
		return

	# determine insertion index (prefer placeholder location)
	var insert_index = original_index
	if placeholder and placeholder.get_parent() == original_parent:
		insert_index = original_parent.get_children().find(placeholder)

	# remove from current parent and re-add into original_parent at insert_index
	var curp = get_parent()
	if curp:
		curp.remove_child(self )
	original_parent.add_child(self )
	original_parent.move_child(self , clamp(insert_index, 0, original_parent.get_child_count()))

	# cleanup placeholder
	if placeholder and placeholder.get_parent():
		placeholder.queue_free()
	placeholder = null
	original_parent = null
	original_index = -1
	target_scale = Vector2.ONE
	scale = Vector2.ONE
	z_index = 0
	_set_top_level_preserve(false)

func _set_top_level_preserve(value: bool) -> void:
	if top_level == value:
		return
	# store both global and local position for robust restoration
	var gp = global_position
	var _lp = position
	top_level = value
	# only adjust position if there was actually a change in coordinates
	var new_gp = global_position
	if new_gp.distance_to(gp) > 1.0:
		global_position = gp

func _finish_return() -> void:
	# no-op; kept for compatibility if referenced elsewhere
	_end_drag()
