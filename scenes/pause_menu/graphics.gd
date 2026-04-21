# Pause Settings Menu - Graphics
extends Control

@onready var fullscreen_button = $"gsettingsoptions/FullScreen button"
@onready var fullscreen_on = $"gsettingsoptions/FullScreen button/Fullscreen ON"
@onready var fullscreen_off = $"gsettingsoptions/FullScreen button/Fullscreen OFF"

func _ready() -> void:
	#startup
	setup_button_hover(fullscreen_button)
	
	#Connect Buttons
	fullscreen_button.pressed.connect(_on_full_screen_button_pressed)
	pass

func _on_full_screen_button_pressed() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_on.hide()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_off.show()
	else:
		fullscreen_off.hide()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_on.show()


#button hover
func tween_button_scale(button: Control, target_scale: Vector2):
	var tween = create_tween()
	tween.tween_property(button, "scale", target_scale, 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func setup_button_hover(button: BaseButton):
	button.mouse_entered.connect(func():
		tween_button_hover(button, true)
		#start_hover_pulse(button)
	)
	
	button.mouse_exited.connect(func():
		tween_button_hover(button, false)
	)

func tween_button_hover(button: BaseButton, hovering: bool):
	var tween = create_tween()
	
	if hovering:
		tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1.15, 1.15, 1.15), 
			0.15
		)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1, 1, 1), 
			0.15
		)
