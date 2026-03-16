extends Control

@onready var background : Sprite2D = $Background
@onready var title = $Title/TitleText
@onready var buttons = $Buttons
@onready var exit_button : Button = $Buttons/Exit
@onready var play_button : Button = $Buttons/Play
@onready var intro_anim = $AnimationPlayer
@onready var shimmer_anim = $Title/AnimationPlayer
@onready var shimmer_timer = $Timer


func _ready():
	randomize()
	
	setup_button_hover(play_button)
	setup_button_hover(exit_button)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.pressed.connect(_on_play_pressed)
	
	#Initial States
	background.modulate.a = 0.0
	title.scale = Vector2(0.1, 0.1)
	buttons.modulate.a = 0.0
	buttons.scale = Vector2(0.8, 0.8)
	
	intro_anim.play("intro")
	intro_anim.queue("hover")
	
	# Setup shimmer timer
	start_shimmer_loop()


#makes the glimmer that goes across title text
func start_shimmer_loop():
	while true:
		await get_tree().create_timer(randf_range(4.0, 8.0)).timeout
		shimmer_anim.play("glimmer")


func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")


func _on_exit_pressed():
	get_tree().quit()


#used for buttons
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
		tween.tween_property(button, "scale", Vector2(2.08, 2.08), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1.15, 1.15, 1.15), 
			0.15
		)
	else:
		tween.tween_property(button, "scale", Vector2(2.0, 2.0), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1, 1, 1), 
			0.15
		)


#func start_hover_pulse(button):
	#while button.is_hovered():
		#var tween = create_tween()
		#tween.tween_property(button, "self_modulate", Color(1.2,1.2,1.2), 0.8)
		#tween.tween_property(button, "self_modulate", Color(1.1,1.1,1.1), 0.8)
		#await tween.finished
