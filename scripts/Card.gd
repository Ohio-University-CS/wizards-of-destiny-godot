@tool
extends Control

signal card_clicked

static var selected_card = null

var card_instance: CardInstance
@export_group("Editor Preview")
@export var preview_card_data: CardData:
	set(value):
		preview_card_data = value
		if Engine.is_editor_hint():
			call_deferred("_refresh_visual")

# Hover & Animation
@export_group("Interaction")
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var lerp_speed: float = 10.0
@export var selected_z_index: int = 20
@export var selected_y_index: int = 10
@export var drag_threshold: float = 8.0

# Card size
@export_group("Layout")
@export var x_size: float = 150
@export var y_size: float = 220

# Tilt Settings
@export_group("Tilt")
@export var max_tilt_angle := 15.0 # Max degrees for movement tilt
@export var mouse_tilt_amount := 5.0 # Max degrees for hovering tilt
@export var tilt_speed := 0.1
@export var return_speed := 0.05

var is_hovered: bool = false
var is_selected: bool = false
var is_dragging: bool = false
var drag_offset := Vector2.ZERO
var has_dragged: bool = false
var ignore_release_toggle: bool = false
var press_global_mouse_pos := Vector2.ZERO
var rest_position := Vector2.ZERO
var target_scale: Vector2 = Vector2.ONE
var last_pos := Vector2.ZERO
var current_tilt := 0.0

func _ready():
	# Use connect in Godot 4.x style for safety
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	set_card_size(x_size, y_size)
	rest_position = position
	last_pos = global_position
	_refresh_visual()


func _exit_tree():
	if selected_card == self:
		selected_card = null


func _process(delta: float):
	if is_dragging:
		var drag_distance = press_global_mouse_pos.distance_to(get_global_mouse_position())
		if drag_distance >= drag_threshold:
			has_dragged = true

	if is_dragging and has_dragged:
		var target_pos = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_pos, 25 * delta)
	elif not is_selected:
		rest_position = position

	# 1. Scale Interpolation
	scale = scale.lerp(target_scale, lerp_speed * delta)
	
	# 2. Movement Tilt Logic
	var move_velocity = global_position.x - last_pos.x
	last_pos = global_position
	
	var movement_target = clamp(move_velocity * 0.5, -max_tilt_angle, max_tilt_angle)
	
	# 3. Mouse Hover Tilt Logic (Balatro-style subtle leaning)
	var mouse_target = 0.0
	if is_hovered:
		var mouse_pos = get_local_mouse_position()
		# Calculate -1.0 to 1.0 based on mouse position relative to center
		var center_offset = (mouse_pos.x - (size.x / 2)) / (size.x / 2)
		mouse_target = center_offset * mouse_tilt_amount

	# 4. Combine and Apply Tilt
	var final_target = movement_target + mouse_target
	
	if abs(move_velocity) > 0.1 or is_hovered:
		current_tilt = lerp(current_tilt, final_target, tilt_speed)
	else:
		current_tilt = lerp(current_tilt, 0.0, return_speed)
	
	rotation = deg_to_rad(current_tilt)

func set_card_size(new_x: float, new_y: float):
	custom_minimum_size = Vector2(new_x, new_y)
	size = Vector2(new_x, new_y)
	pivot_offset = size / 2

func _on_mouse_entered():
	is_hovered = true
	_update_visual_state()
	
func _on_mouse_exited():
	is_hovered = false
	_update_visual_state()


func setup(instance: CardInstance):
	card_instance = instance
	_refresh_visual()


func _refresh_visual():
	if not is_inside_tree() or not has_node("TextureRect"):
		return

	var texture_rect: TextureRect = $TextureRect

	if card_instance and card_instance.data:
		texture_rect.texture = card_instance.data.artwork
		return

	if preview_card_data:
		texture_rect.texture = preview_card_data.artwork
		return

	texture_rect.texture = null


func _update_visual_state():
	if is_selected or is_hovered:
		target_scale = hover_scale
	else:
		target_scale = Vector2.ONE
	if is_selected:
		z_index = selected_z_index
	elif is_dragging and has_dragged:
		z_index = selected_z_index + 1
	elif is_hovered:
		z_index = 10
	else:
		z_index = 0
	if is_dragging:
		return
	if is_selected:
		position = Vector2(rest_position.x, rest_position.y - selected_y_index)
	else:
		position = rest_position


func _set_selected(value: bool):
	is_selected = value
	_update_visual_state()


func _toggle_selected():
	if is_selected:
		_set_selected(false)
		if selected_card == self:
			selected_card = null
		return

	if selected_card and is_instance_valid(selected_card) and selected_card != self:
		selected_card._set_selected(false)

	selected_card = self
	_set_selected(true)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.double_click:
					ignore_release_toggle = true
					card_clicked.emit()
					return

				is_dragging = true
				has_dragged = false
				press_global_mouse_pos = get_global_mouse_position()
				drag_offset = get_global_mouse_position() - global_position
				top_level = true
				_update_visual_state()
			else:
				is_dragging = false
				top_level = false
				if has_dragged:
					rest_position = position

				if ignore_release_toggle:
					ignore_release_toggle = false
					_update_visual_state()
					return

				if not has_dragged:
					_toggle_selected()

				_update_visual_state()

	# Optional: Handle hover scaling if mouse moves while not dragging
	if event is InputEventMouseMotion and is_dragging:
		# This ensures movement tilt is updated during the drag
		pass
