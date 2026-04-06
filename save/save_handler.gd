extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Save Handler Ready")
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func write_out_gamestate():
	
	pass


func test_function():
	print("TEST COMPLETE")


func parse_player_state(gamestate_player : Player) -> Dictionary:
	print("PARSING PLAYER STATE")
	var player_state = {}
	var gamestate_dict = {}
	gamestate_dict["current_health"] = gamestate_player.current_health
	gamestate_dict["energy"] = gamestate_player.energy
	gamestate_dict["max_energy"] = gamestate_player.max_energy
	### SHOULD I PUT BASE STATS??

	player_state["gamestate"] = gamestate_dict
	player_state["perm_modifiers"] = gamestate_player.perm_modifiers
	print(gamestate_player.perm_modifiers)
	print(gamestate_dict)
	player_state["deck_list"] = {}
	for card in gamestate_player.deck_list:
		print(card)
		
	return {}
