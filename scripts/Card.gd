extends Control

signal card_clicked

var card_instance : CardInstance

# Hover & Animation
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var lerp_speed: float = 10.0

# Card size
@export var x_size: float = 150
@export var y_size: float = 220

# Tilt Settings
@export var max_tilt_angle := 15.0  # Max degrees for movement tilt
@export var mouse_tilt_amount := 5.0 # Max degrees for hovering tilt
@export var tilt_speed := 0.1
@export var return_speed := 0.05

var is_hovered: bool = false
var is_dragging: bool = false
var drag_offset := Vector2.ZERO
var target_scale: Vector2 = Vector2.ONE
var last_pos := Vector2.ZERO
var current_tilt := 0.0

func _ready():
	# Use connect in Godot 4.x style for safety
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	set_card_size(x_size, y_size)
	last_pos = global_position


func _process(delta: float):
	# 1. Scale Interpolation
	scale = scale.lerp(target_scale, lerp_speed * delta)
	
	# 2. Movement Tilt Logic
	var move_velocity = global_position.x - last_pos.x
	last_pos = global_position
	
	var movement_target = clamp(move_velocity * 0.5, -max_tilt_angle, max_tilt_angle)
	
	# 3. Mouse Hover Tilt Logic (Balatro-style subtle leaning)
	var mouse_target = 0.0
	if is_dragging:
		var target_pos = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_pos, 25 * delta)
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
	target_scale = hover_scale
	z_index = 10 
	
func _on_mouse_exited():
	is_hovered = false
	target_scale = Vector2.ONE
	z_index = 0


func setup(instance : CardInstance):
	card_instance = instance
	$TextureRect.texture = instance.data.artwork


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# START DRAG
				is_dragging = true
				top_level = true 
				# Calculate where we grabbed the card to avoid snapping
				drag_offset = get_global_mouse_position() - global_position
				
				# The "Balatro" click punch
				scale = Vector2(0.9, 0.9)
				card_clicked.emit()
			else:
				# STOP DRAG
				is_dragging = false
				top_level = false
				# Reset z_index if you changed it
				z_index = 0

	# Optional: Handle hover scaling if mouse moves while not dragging
	if event is InputEventMouseMotion and is_dragging:
		# This ensures movement tilt is updated during the drag
		pass
