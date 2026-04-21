extends Control

@onready var Main_menu_animation: AnimatedSprite2D = $Animations/main_menu_scroll_animation
@onready var Quit_Animation = $Animations/quit_scroll_animation

@onready var quit_button = $quit_button
@onready var main_menu_button = $main_menu_button

func _ready() -> void:
	
	Main_menu_animation.speed_scale = 2.0
	Quit_Animation.speed_scale = 2.0
	
	main_menu_button.hide()
	quit_button.hide()
	Main_menu_animation.show()
	Main_menu_animation.play("Open")
	await Main_menu_animation.animation_finished
	main_menu_button.show()
	Main_menu_animation.hide()
	
	Quit_Animation.show()
	Quit_Animation.play("Open")
	await Quit_Animation.animation_finished
	quit_button.show()
	Quit_Animation.hide()
	
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	setup_button_hover(main_menu_button)
	setup_button_hover(quit_button)


func _on_main_menu_pressed():
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
	pass

func _on_quit_pressed():
	get_tree().quit()
	get_tree().paused = false
	visible = false
	pass


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
