extends Control
@onready var save_1_button : Button = $"Buttons/Save1Button"
@onready var save_2_button : Button = $"Buttons/Save2Button"
@onready var save_3_button : Button = $"Buttons/Save3Button"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save_1_button.pressed.connect(select_save_1)
	save_2_button.pressed.connect(select_save_2)
	save_3_button.pressed.connect(select_save_3)






func select_save_1():
	print("Save 1 Selected")
	GameStateManager._select_save(1)
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
	
func select_save_2():
	print("Save 2 Selected")
	GameStateManager._select_save(2)
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")

func select_save_3():
	print("Save 3 Selected")
	GameStateManager._select_save(3)
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
