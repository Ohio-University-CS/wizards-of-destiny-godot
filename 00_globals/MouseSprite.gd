# Mouse Sprite
extends Node

var normal_cursor = load("res://art_drop/WOD_Mouse_Sprite.png")
var click_cursor = load("res://art_drop/WOD_Mouse_Sprite_2.png")


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(normal_cursor)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			Input.set_custom_mouse_cursor(click_cursor)
		else:
			Input.set_custom_mouse_cursor(normal_cursor)
