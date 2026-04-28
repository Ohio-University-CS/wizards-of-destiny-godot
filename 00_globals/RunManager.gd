# RunManager.gd
# Handles run information
extends Node

# ----------------
# Core Run Data
# ----------------

var player: Player = null
var coins: int = 10

var run_seed: int = -1
var _rng := RandomNumberGenerator.new()

var seed_scene: bool = false

var item_inventory: Array[ItemData] = []

var current_level: LevelType = LevelType.FOREST
var level_floor: int = 1
var stage: int = 1

enum StageType {
	NORMAL,
	ELITE,
	BOSS
}

enum LevelType {
	FOREST
}

signal run_progress_changed(level_name: String, floor: int, stage_number: int)

var last_combat_result: Dictionary = {}

# ----------------
# Run Setup
# ----------------

func start_new_run(starting_player: Player, new_seed: int = -1):
	# Unlock all items at the start
	for item in ItemUnlockManager.all_items:
		ItemUnlockManager.unlock_item(item.item_name)

	item_inventory.clear()
	player = starting_player
	coins = 10
	current_level = LevelType.FOREST
	level_floor = 1
	stage = 1
	if new_seed == -1:
		run_seed = randi()
	else:
		run_seed = new_seed
	_rng.seed = run_seed
	print("Run Seed: ", run_seed)
	_emit_run_progress_changed()



func load_run_from_save():
		# Unlock all items at the start
	if(!GameStateManager.game_loaded):
		return
	for item in ItemUnlockManager.all_items:
		ItemUnlockManager.unlock_item(item.item_name)

	item_inventory.clear()
	player = GameStateManager.gamestate_player
	coins = GameStateManager.gamestate_coins
	current_level = LevelType.FOREST
	level_floor = GameStateManager.gamestate_level_floor
	stage = GameStateManager.gamestate_stage
	run_seed = GameStateManager.gamestate_seed
	_rng.seed = run_seed
	print("Run Seed: ", run_seed)
	_emit_run_progress_changed()
	
	
func get_rng() -> RandomNumberGenerator:
	return _rng

# ----------------
# Progression
# ----------------

func add_coins(amount: int):
	#run_seed = randi() # fallback to random seed if not provided
	coins += amount


func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false

func next_stage():
	print("MOVING TO NEXT STAGE")
	stage += 1
	
	if stage > 12:
		stage = 1
		level_floor += 1

	_emit_run_progress_changed()


func set_current_level(new_level: LevelType):
	current_level = new_level
	_emit_run_progress_changed()


func get_level_name() -> String:
	var level_keys := LevelType.keys()
	if current_level < 0 or current_level >= level_keys.size():
		return "Unknown"
	return str(level_keys[current_level]).capitalize()


func _emit_run_progress_changed():
	emit_signal("run_progress_changed", get_level_name(), level_floor, stage)

# ----------------
# Stage Type Logic
# ----------------

func get_stage_type() -> StageType:
	if stage in [4, 8]:
		return StageType.ELITE
	if stage == 12:
		return StageType.BOSS
	return StageType.NORMAL


# ---------------------------------------------------------
# Items
# ---------------------------------------------------------

func has_item(iname: String) -> bool:
	if item_inventory.size() == 0:
		return false
	for i in item_inventory:
		if iname == i.item_name:
			return true
	return false


func add_item(item: ItemData):
	if item not in item_inventory:
		item_inventory.append(item)
		
		# Holy Goblet
		if item.item_name == "Holy Goblet":
			player.max_energy += 1
		
		# Recalculate stats if player exists
		if player:
			player.set_perm_stats()


func remove_item(item: ItemData):
	if item in item_inventory:
		item_inventory.erase(item)


func remove_item_by_name(iname: String):
	for i in item_inventory:
		if iname == i.item_name:
			item_inventory.erase(i)


signal player_changed(new_player)

# When setting the player, emit the signal
func set_player(new_player):
	player = new_player
	emit_signal("player_changed", new_player)


func remove_card_from_deck(index: int):
	player.deck_list.pop_at(index)
