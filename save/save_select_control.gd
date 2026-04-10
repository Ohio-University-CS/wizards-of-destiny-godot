extends Control

@onready var save1_button : Button = $Buttons/Save1
@onready var save2_button : Button = $Buttons/Save2
@onready var save3_button : Button = $Buttons/Save3


const LEVEL_SELECT_SCENE = "res://scenes/Level Select/level_1.tscn"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	save1_button.pressed.connect(_on_save_1_pressed)
	save2_button.pressed.connect(_on_save_2_pressed)
	save3_button.pressed.connect(_on_save_3_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_save_1_pressed():
	print("[*]Save 1 button pressed...")
	GameStateManager._select_save(1)
	## GameStateManager._load_selected_save()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	
func _on_save_2_pressed():
	print("[*]Save 2 button pressed...")
	GameStateManager._select_save(2)
	## GameStateManager._load_selected_save()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

func _on_save_3_pressed():
	print("[*]Save 3 button pressed...")
	GameStateManager._select_save(3)
	## GameStateManager._load_selected_save()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
