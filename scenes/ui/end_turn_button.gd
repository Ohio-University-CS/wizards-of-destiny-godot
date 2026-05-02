# End Turn Button
extends Button

signal end_turn_requested


func _ready() -> void:
	pressed.connect(_on_pressed)
	_connect_end_turn_listeners()


func _on_pressed() -> void:
	end_turn_requested.emit()


func _connect_end_turn_listeners() -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var manager = scene_root if scene_root.name == "GameManager" else scene_root.find_child("GameManager", true, false)
	if manager and manager.has_method("force_end_player_turn"):
		end_turn_requested.connect(Callable(manager, "force_end_player_turn"))

	var temp_combat = scene_root if scene_root.name == "TempCombat" else scene_root.find_child("TempCombat", true, false)
	if temp_combat and temp_combat.has_method("force_end_player_turn"):
		end_turn_requested.connect(Callable(temp_combat, "force_end_player_turn"))
