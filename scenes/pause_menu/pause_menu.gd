extends Control

@onready var resume_button : Button = $Buttons/resume_button
@onready var settings_button : Button = $Buttons/settings_button
@onready var exit_button : Button = $Buttons/quit_button
@onready var main_menu_button : Button = $Buttons/main_menu_button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_resume_pressed():
	pass

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/pause_menu/pause_graphics/pause_settings_graphics.tscn")
	pass

func _on_exit_pressed():
	get_tree().quit()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen/title_page.tscn")
