# Game State Manager
extends Node

func _ready() -> void:
	var player_dict = get_run_player_state()
	for key in player_dict:
		print(key + " : " + player_dict[key])
	


func get_run_player_state() -> Dictionary:
	var _player_script = load("res://scenes/player/Player.gd")
	var _player_state = {}
	#player_state.
	
	return {}
