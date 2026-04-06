extends Control

@onready var AnimatedSprite: AnimatedSprite2D = $Pause_Settings_menu/Scroll_Animation/AnimatedSprite2D
@onready var pause_menu_options = $Pause_menu_options
@onready var pause_settings_menu = $Pause_Settings_menu
@onready var graphics_menu = $Pause_Settings_menu/graphics
@onready var graphics_menu_options = $"Pause_Settings_menu/graphics/gsettingsoptions"
@onready var sound_menu = $"Pause_Settings_menu/sound"
@onready var sound_menu_options = $"Pause_Settings_menu/sound/soundsettingoptions"
@onready var controls_menu = $Pause_Settings_menu/controls
@onready var unrolled_scroll = $Unrolled_Scroll

# Button References
@onready var settings_button = $Pause_menu_options/Buttons/settings_button
@onready var graphics_button = $"Pause_Settings_menu/Buttons/Graphics Button"
@onready var sound_button = $"Pause_Settings_menu/Buttons/Sound Button"
@onready var controls_button = $"Pause_Settings_menu/Buttons/Control Button"
@onready var back_button = $"Pause_Settings_menu/Buttons/Back Button"
@onready var resume_button = $"Pause_menu_options/Buttons/resume_button"
@onready var main_menu_button = $"Pause_menu_options/Buttons/main_menu_button"
@onready var quit_button = $Pause_menu_options/Buttons/quit_button

#scroll animations
@onready var resume_animation = $"Pause_menu_options/Scroll_Animation/resume_scroll_animation"
@onready var settings_animation = $Pause_menu_options/Scroll_Animation/setting_scroll_animation
@onready var main_menu_animation = $"Pause_menu_options/Scroll_Animation/main_menu_button"
@onready var quit_animation = $"Pause_menu_options/Scroll_Animation/quit_scroll_animation"

#Button Sprites
@onready var graphics_button_Normal = $"Pause_Settings_menu/Buttons/Graphics Button/Graphics"
@onready var sound_button_Normal = $"Pause_Settings_menu/Buttons/Sound Button/Sound"
@onready var controls_button_Normal = $"Pause_Settings_menu/Buttons/Control Button/Controls"

@onready var graphics_button_Blue = $"Pause_Settings_menu/Buttons/Graphics Button/Graphics_Blue"
@onready var sound_button_Blue = $"Pause_Settings_menu/Buttons/Sound Button/Sound_Blue"
@onready var controls_button_Blue = $"Pause_Settings_menu/Buttons/Control Button/Controls_Blue"

func _ready() -> void:
	_pause_settings_menu_off()
	unrolled_scroll.hide()
	AnimatedSprite.speed_scale = 2.0  # 2x faster
	resume_animation.speed_scale = 2.0
	settings_animation.speed_scale = 2.0
	main_menu_animation.speed_scale = 2.0
	quit_animation.speed_scale = 2.0
	_pause_menu_scroll_animation()
	
	#Setup Button Hover
	setup_button_hover(graphics_button)
	setup_button_hover(sound_button)
	setup_button_hover(controls_button)
	
	#Connect all buttons
	settings_button.pressed.connect(_on_settings_pressed)
	graphics_button.pressed.connect(_on_graphics_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	back_button.pressed.connect(_on_back_pressed)
	resume_button.pressed.connect(_on_resume_pressed)

func _on_settings_pressed() -> void:
	_pause_menu_off()
	_pause_settings_menu_on()
	unrolled_scroll.visible = false
	sound_menu.visible = false
	controls_menu.visible = false
	graphics_menu_options.visible = false
	sound_button_Blue.visible = false
	controls_button_Blue.visible = false
	graphics_button_Blue.visible = true
	
	AnimatedSprite.show()
	AnimatedSprite.play("Open")
	await AnimatedSprite.animation_finished
	
	graphics_menu.visible = true
	graphics_button_Blue.visible = true
	unrolled_scroll.show()
	AnimatedSprite.hide()
	graphics_menu_options.visible = true
	
func _on_graphics_pressed() -> void:
	sound_menu.visible = false
	controls_menu.visible = false
	graphics_menu.visible = true
	graphics_menu_options.visible = false
	sound_button_Blue.visible = false
	controls_button_Blue.visible = false
	graphics_button_Blue.visible = true
	await _play_scroll_transition()
	
	graphics_menu_options.visible = true

func _on_sound_pressed() -> void:
	graphics_menu.visible = false
	controls_menu.visible = false   # FIX: Moved this up before the animation!
	sound_menu.visible = true
	sound_menu_options.visible = false
	sound_button_Blue.visible = true
	controls_button_Blue.visible = false
	graphics_button_Blue.visible = false
	
	await _play_scroll_transition()
	
	sound_menu_options.visible = true

func _on_controls_pressed() -> void:
	# FIX: Swapped the menus BEFORE the animation plays
	graphics_menu.visible = false
	sound_menu.visible = false
	controls_menu.visible = true
	sound_button_Blue.visible = false
	controls_button_Blue.visible = true
	graphics_button_Blue.visible = false
	# Note: If you add a "controls_menu_options" node later like you did for 
	# graphics and sound, be sure to hide it here, and show it after the await!
	
	await _play_scroll_transition()

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_back_pressed() -> void:
	print("Back pressed")
	unrolled_scroll.visible = false
	sound_menu_options.visible = false
	#controls_menu_options.visible = false
	graphics_menu_options.visible = false
	AnimatedSprite.show()
	AnimatedSprite.play("Close")
	await AnimatedSprite.animation_finished
	_pause_settings_menu_off()
	_pause_menu_on()
	_pause_menu_scroll_animation()

#Reusable helper function for the scroll animation
func _pause_menu_scroll_animation() -> void:
	#Button Visibility set false
	resume_button.visible = false
	resume_animation.visible =false
	settings_button.visible = false
	settings_animation.visible = false
	main_menu_button.visible = false
	main_menu_animation.visible = false
	quit_button.visible = false
	quit_animation.visible = false
	
	#Disable Buttons
	resume_button.disabled = true
	settings_button.disabled = true
	main_menu_button.disabled = true
	quit_button.disabled = true
	
	#Animation
	resume_animation.visible = true
	resume_animation.play("Open")
	await resume_animation.animation_finished
	resume_button.visible = true
	resume_animation.visible = false
	settings_animation.visible = true
	settings_animation.play("Open")
	await settings_animation.animation_finished
	settings_button.visible = true
	settings_animation.visible = false
	main_menu_animation.visible = true
	main_menu_animation.play("Open")
	await main_menu_animation.animation_finished
	main_menu_button.visible = true
	main_menu_animation.visible = false
	quit_animation.visible = true
	quit_animation.play("Open")
	await quit_animation.animation_finished
	quit_button.visible = true
	quit_animation.visible = false
	
	#Enable Buttons
	resume_button.disabled = false
	settings_button.disabled = false
	main_menu_button.disabled = false
	quit_button.disabled = false
#Reusable helper function for the settings menu scroll animation
func _play_scroll_transition() -> void:
	#control_button.disabled = false
	sound_button.disabled = false
	graphics_button.disabled = false
	
	unrolled_scroll.hide()
	AnimatedSprite.show()
	AnimatedSprite.play("Close")
	await AnimatedSprite.animation_finished
	AnimatedSprite.play("Open")
	await AnimatedSprite.animation_finished
	unrolled_scroll.show()
	AnimatedSprite.hide()
	
func _pause_menu_off() -> void:
	pause_menu_options.visible = false

func _pause_settings_menu_off() -> void:
	pause_settings_menu.visible = false

func _pause_menu_on() -> void:
	pause_menu_options.visible = true

func _pause_settings_menu_on() -> void:
	pause_settings_menu.visible = true


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
