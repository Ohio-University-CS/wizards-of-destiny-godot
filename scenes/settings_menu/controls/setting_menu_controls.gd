extends Control

@onready var AnimatedSprite: AnimatedSprite2D = $Scroll_Animation/AnimatedSprite2D
@onready var graphics_button = $"Buttons/Graphics Button"
@onready var sound_button = $"Buttons/Sound Button"
@onready var control_button = $"Buttons/Control Button"
@onready var exit_button : Button = $Buttons/Exit
@onready var unrolled_scroll = $Unrolled_Scroll


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#visibility
	AnimatedSprite.speed_scale = 2.0  # 2x faster
	_cs_on()
	#settings
	#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	#buttons
	setup_button_hover(graphics_button)
	setup_button_hover(sound_button)
	setup_button_hover(control_button)
	graphics_button.pressed.connect(_on_graphics_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	
	exit_button.pressed.connect(_on_back_pressed)
	



func _cs_on() -> void:
	unrolled_scroll.hide()
	AnimatedSprite.play("Open")
	await AnimatedSprite.animation_finished
	unrolled_scroll.show()


func _cs_off() -> void:
	unrolled_scroll.hide()

func _on_graphics_pressed():
	graphics_button.disabled = true
	control_button.disabled = true
	unrolled_scroll.hide()
	_cs_off()
	AnimatedSprite.play("Close")
	await AnimatedSprite.animation_finished
	get_tree().change_scene_to_file("res://scenes/settings_menu/graphics/setting-menu-graphics.tscn")
	control_button.disabled = false
	graphics_button.disabled = false
	pass

func _on_sound_pressed():
	control_button.disabled = true
	sound_button.disabled = true
	unrolled_scroll.hide()
	_cs_off()
	AnimatedSprite.play("Close")
	await AnimatedSprite.animation_finished
	get_tree().change_scene_to_file("res://scenes/settings_menu/sound/settings-menu-sound.tscn")
	control_button.disabled = false
	sound_button.disabled = false
	

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")

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
