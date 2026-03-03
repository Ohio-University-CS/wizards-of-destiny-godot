extends Control

@export var hover_scale := 1.1
@export var hover_offset := -20.0 # Lift card up when hovered
@export var lerp_speed := 0.15

var target_pos: Vector2
var target_scale := Vector2.ONE

func _ready():
	# # Connect signals for hovering
	# mouse_entered.connect(_on_mouse_entered)
	# mouse_exited.connect(_on_mouse_exited)
	
	# # Set pivot to center so it scales from the middle
	# pivot_offset = size / 2
	pass

func _process(_delta):
	# Smoothly move to target scale and position
	scale = scale.lerp(target_scale, lerp_speed)
	# Using position.y for the "lift" effect
	position.y = lerp(position.y, target_pos.y, lerp_speed)

func _on_mouse_entered():
	target_scale = Vector2.ONE * hover_scale
	target_pos.y = hover_offset
	z_index = 1 # Bring to front when hovering

func _on_mouse_exited():
	target_scale = Vector2.ONE
	target_pos.y = 0
	z_index = 0
