extends Control

var pause_menu_scene = preload("res://scenes/pause_menu/pause-menu.tscn")
var pause_menu = null

func _ready():
	pause_menu = pause_menu_scene.instantiate()
	pause_menu.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_menu)
	
	

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	pause_menu.visible = get_tree().paused
