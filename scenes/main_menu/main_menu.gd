extends Control

@onready var levels_button : Button = $"Buttons/LevelSelect"
@onready var collection_button : Button = $Buttons/Collection
@onready var settings_button : Button = $Buttons/Settings
@onready var exit_button : Button = $Buttons/Exit
@onready var info_button : Button = $Buttons/Info


func _ready() -> void:
	setup_button_hover(levels_button)
	setup_button_hover(collection_button)
	setup_button_hover(settings_button)
	setup_button_hover(exit_button)
	setup_button_hover(info_button)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	levels_button.pressed.connect(_on_level_select_pressed)
	collection_button.pressed.connect(_on_collections_pressed)
	info_button.pressed.connect(_on_info_pressed)

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/settings_menu/graphics/setttings-menu-graphics.tscn")


### WE GOTTA CHANGE THIS BUTTON TO SELECT SAVE OR SOMETHING
func _on_level_select_pressed():
	#get_tree().change_scene_to_file("res://scenes/Level Select/level_1.tscn")
	get_tree().change_scene_to_file("res://save/save_select_screen.tscn")

func _on_collections_pressed():
	get_tree().change_scene_to_file("res://scenes/collection/collection.tscn")

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/title_page.tscn")

func _on_info_pressed():
	get_tree().change_scene_to_file("res://scenes/info_page/Info_Page.tscn")



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
