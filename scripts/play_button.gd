extends Button

signal play_hand_requested


func _ready() -> void:
	pressed.connect(_on_pressed)
	_connect_play_listeners()


func _on_pressed() -> void:
	play_hand_requested.emit()


func _connect_play_listeners() -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var manager = scene_root if scene_root.name == "GameManager" else scene_root.find_child("GameManager", true, false)
	if manager and manager.has_method("play_hand"):
		play_hand_requested.connect(Callable(manager, "play_hand"))

	var temp_combat = scene_root if scene_root.name == "TempCombat" else scene_root.find_child("TempCombat", true, false)
	if temp_combat and temp_combat.has_method("play_hand"):
		play_hand_requested.connect(Callable(temp_combat, "play_hand"))
