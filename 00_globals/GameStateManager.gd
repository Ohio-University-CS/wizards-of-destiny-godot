# Game State Manager
extends Node

var selected_save : String = "" ### IMPLEMENT SAVE CHOOSING SCENE TO INITIALIZE
var gamestate_player : Player = null
var gamestate_coins : int = 0
var num_battles : int = 0
var gamestate_stage : int = 1
var gamestate_level_floor : int = 1
var gamestate_inventory : Array[ItemData] = []

var save_file_path : String = ""
var save_resources_path : String = ""
var backup_save_path : String = ""

var gamestate_save_data : Dictionary = {}

var num_cards_in_deck : int = 10

func _ready() -> void:
	print("[*]Gamestate manager ready...")
	### SELECTED SAVE SHOULD NOT BE HARDCODED TO 1, CHANGE WHEN SAVE SELECTION IMPLEMENTED
	get_tree().scene_changed.connect(_on_scene_change)
	GameEventSignaler.combat_end.connect(_on_combat_end)
	GameEventSignaler.next_combat_begin.connect(_on_exit_shop)
	
func _on_combat_end(player : Player):
	print("[*]Combat ended, saving...")
	_read_current_game_state()
	_save_game_state()
	

func _select_save(save_number : int):
	match(save_number):
		1:
			selected_save = "save_1"
		2:
			selected_save = "save_2"
		3:
			selected_save = "save_3"
		_:
			selected_save = "save_1"
	print("[*]Save " + selected_save + " selected...")
			


func _on_scene_change():
	var current_scene_name = get_tree().get_current_scene().name
	#var current_scene_path = get_tree().get_current_scene().get_path().get_concatenated_names()
	#print(current_scene_path)
	if(current_scene_name == "Arena"):
		print("[*]Arena entered...")
	elif(current_scene_name.begins_with("Level")):
		print("[*]Level select entered...")


func _on_exit_shop(_player: Player = null):
	print("[*]Shop exited...")
	pass
	#_update_current_gamestate()
	#if _write_out_gamestate():
		#print("Write to save file successful")
	#else:
		#print("Write to save file res://save/" + selected_save + ".json unsuccessful")


func _read_current_game_state():
	print("Gamestate updated...")
	if(RunManager.player == null):
		push_error("_read_current_game_state: ERROR, Player in RunManager is not initialized")
		return
		
	gamestate_player = RunManager.player
	gamestate_coins = RunManager.coins
	gamestate_stage = RunManager.stage
	gamestate_level_floor = RunManager.level_floor
	gamestate_inventory.clear()
	for item in RunManager.item_inventory:
		gamestate_inventory.append(item)
	return
	
	
	
	
func _save_deck(resource_folder_path : String):
	var array_index = 0
	for card in gamestate_player.deck_list:
		var save_path = resource_folder_path + "/cards/card_" + str(array_index + 1) + ".tres"
		print("[*]Saving card to " + save_path)
		ResourceSaver.save(card, save_path)
		array_index += 1
	print("[*]Saving cards complete")
	
	
func _save_item_inventory(resource_folder_path : String):
	var array_index = 0
	for item in gamestate_inventory:
		var save_path = resource_folder_path + "/inventory/item_" + str(array_index + 1) + ".tres"
		print("[*]Saving item to " + save_path)
		ResourceSaver.save(item, save_path)
		array_index += 1
	print("[*]Saving inventory complete")
	pass
	
### Assign file path variables for easy reuse
func _assign_save_file_path():
	save_file_path = "res://save/" + selected_save + ".json"
func _assign_save_resources_path():
	save_resources_path = "res://save/" + selected_save + "_resources"
func _assign_backup_path():
	backup_save_path = "res://save/" + selected_save + "_resources/backup/" + selected_save + "_backup.json"
	
### Creates a backup of <filename>.json to save_<x>_resources/backup/<filename>_backup.json
func _create_save_backup(origin_file_path : String, backup_file_path):
	if(!FileAccess.file_exists(origin_file_path)):
		push_error("_create_save_backup: ERROR, original save file doesn't exist as passed")
		return
	var save_data_string = FileAccess.get_file_as_string(origin_file_path)
	var backup_file = FileAccess.open(backup_file_path, FileAccess.WRITE)
	backup_file.store_string(save_data_string)
	backup_file.close()
	return
	
	
func _save_game_state():
	### Assign or update all save file paths
	_assign_save_file_path()
	_assign_save_resources_path()
	_assign_backup_path()
	### Create a backup before writing out
	_create_save_backup(save_file_path, backup_save_path)
	_write_out_gamestate(save_file_path)
	### Save items in inventory and player deck
	_save_item_inventory(save_resources_path)
	_save_deck(save_resources_path)
	print("Game state saved...")
	return
	
### Write out all continous player atrributes (health, max stats, modifiers)
func _write_out_player_state_string(player : Player) -> Dictionary:
	var player_state = {}
	player_state["current_health"] = gamestate_player.current_health
	player_state["max_energy"] = gamestate_player.max_energy
	player_state["perm_modifiers"] = gamestate_player.perm_modifiers
	player_state["num_cards_in_deck"] = gamestate_player.deck_list.size()
	return player_state
	
### Write out game state (player state, stage, level, coins, etc.) to <selected_save>.json
func _write_out_gamestate(file_path : String) -> bool:
	var player_state_dict = _write_out_player_state_string(gamestate_player)
	var save_data = {
		"player_state": player_state_dict,
		"coins": gamestate_coins,
		"stage": gamestate_stage,
		"level_floor": gamestate_level_floor,
	}
	var save_file = FileAccess.open(str(file_path), FileAccess.WRITE)
	var save_data_string = JSON.stringify(save_data, "\t")
	save_file.store_string(save_data_string)
	save_file.close()
	
	print("Save Successful")
	return true
	
func _load_game_from_save(file_path : String):
	### ASSIGN FILE PATHS
	### INPUT SAVE JSON TEXT
	### VALIDATE SAVE JSON
		### IF CORRUPTED, LOAD BACKUP
	### LOAD GAMESTATE
	### LOAD DECK
	### LOAD INVENTORY
	pass

#
#func _get_deck_from_save(resource_folder_path) -> Array[CardData]:
	#print("GET DECK FROM SAVE")
	#var card_number = 1
	#var deck_array : Array[CardData] = []
	#while FileAccess.file_exists(resource_folder_path + "/card_" + str(card_number) + ".tres"):
		#print("card_" + str(card_number) + " exists")
		#var this_card_path = resource_folder_path + "/card_" + str(card_number) + ".tres"
		#var temp_card_data = load(this_card_path)
		#deck_array.append(temp_card_data)
		#card_number += 1
	#for card in deck_array:
		#print(card)
	#return deck_array
	#
#
#
#
#func _save_inventory(resource_folder_path : String, item_inventory : Array[ItemData]):
	#var array_index = 0
	#for item in item_inventory:
		#var save_path = resource_folder_path + "/inventory/item_" + str(array_index + 1) + ".tres"
		#print(save_path)
		#ResourceSaver.save(item, save_path)
		#array_index += 1
	#print("saving inventory complete")
#
#
#
#func _read_gamestate_from_save(save_file_path) -> bool:
	#if FileAccess.file_exists(save_file_path):
		#var save_file_string = FileAccess.get_file_as_string(save_file_path)
		#var save_data = JSON.parse_string(save_file_string)
		#if save_data is Dictionary:
			#gamestate_save_data = save_data
			#return true
	#return false
#
# func _get_inventory_from_save(resource_folder_path) -> Array[ItemData]:
# 	print("GET INVENTORY FROM SAVE")
# 	var item_number = 1
# 	var inventory_array : Array[ItemData] = []
# 	while FileAccess.file_exists(resource_folder_path + "/item_" + str(item_number) + ".tres"):
# 		print("item_" + str(item_number) + " exists")
# 		var this_item_path = resource_folder_path + "/item_" + str(item_number) + ".tres"
# 		var temp_item_data = load(this_item_path)
# 		inventory_array.append(temp_item_data)
# 		item_number += 1
# 	for item in inventory_array:
# 		print(item)
# 	return inventory_array
