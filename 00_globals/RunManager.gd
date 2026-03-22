# RunManager.gd
extends Node

# ----------------
# Core Run Data
# ----------------

var player : Player = null
var coins : int = 0

var level_floor : int
var stage : int

enum StageType {
	NORMAL,
	ELITE,
	BOSS
}

var last_combat_result : Dictionary = {}

# ----------------
# Run Setup
# ----------------

func start_new_run(starting_player : Player):
	player = starting_player
	coins = 0
	level_floor = 1
	stage = 1

# ----------------
# Progression
# ----------------

func add_coins(amount : int):
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
