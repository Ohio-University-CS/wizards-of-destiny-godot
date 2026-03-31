# RunManager.gd
# Handles run information
extends Node

# ----------------
# Core Run Data
# ----------------

var player : Player = null
var coins : int = 10

var seed : int = 0
var _rng := RandomNumberGenerator.new()

var seed_scene : bool = false

var item_inventory : Array[ItemData]

var level_floor : int
var stage : int

enum StageType {
	NORMAL,
	ELITE,
	BOSS
}

enum LevelType {
	FOREST
}

var last_combat_result : Dictionary = {}

# ----------------
# Run Setup
# ----------------

func start_new_run(starting_player : Player, new_seed : int = -1):
	item_inventory.clear()
	player = starting_player
	coins = 10
	level_floor = 1
	stage = 1
	if new_seed == -1:
		seed = randi()
	else:
		seed = new_seed
	_rng.seed = seed
	print("Seed: ", seed)

func get_rng() -> RandomNumberGenerator:
	return _rng

# ----------------
# Progression
# ----------------

func add_coins(amount : int):
	seed = randi() # fallback to random seed if not provided

	coins += amount


func spend_coins(amount : int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false

func next_stage():
	stage += 1
	
	if stage > 12:
		stage = 1
		level_floor += 1

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

func has_item(iname : String) -> bool:
	if item_inventory.size() == 0:
		return false
	for i in item_inventory:
		if iname == i.item_name:
			return true
	return false


func add_item(item : ItemData):
	if item not in item_inventory:
		item_inventory.append(item)


func remove_item(item : ItemData):
	if item in item_inventory:
		item_inventory.erase(item)
