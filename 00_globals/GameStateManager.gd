# Game State Manager
extends Node

func _ready() -> void:
	print("GAMESTATEMANAGER READY")
	get_tree().scene_changed.connect(_on_scene_change)
	GameEventSignaler.combat_end.connect(_on_combat_end)
	GameEventSignaler.next_combat_begin.connect(_on_exit_shop)
	


func get_run_player_state() -> Dictionary:
	var _player_script = load("res://scenes/player/Player.gd")
	var _player_state = {}
	#player_state.
	
func _update_current_gamestate():
	print("UPDATING GAMESTATE")
	gamestate_player = RunManager.player
	gamestate_coins = RunManager.coins
	gamestate_stage = RunManager.stage
	gamestate_level_floor = RunManager.level_floor	
	for item in RunManager.item_inventory:
		gamestate_inventory.append(item)

func _on_combat_end(player : Player):
	if(player != null):
		print("player successfully passed")
		_update_current_gamestate()
		_write_out_gamestate()
	else:
		print("Unable to access player data post combat")

func _on_scene_change():
	var current_scene_name = get_tree().get_current_scene().name
	if(current_scene_name == "Arena"):
		print("arena entered")
		_update_current_gamestate()
		
func _on_exit_shop(_player: Player = null):
	_update_current_gamestate()
	_write_out_gamestate()
	
func _write_out_gamestate() -> bool:
	#var player_state_dictionary = {
		#"current health" : gamestate_player.current_health,
		#""
	#}
	return true
"""
@export var initialized : bool = false

# BASE STATS (from class)
var base_max_health: int
var base_damage: int
var base_elemental_power: int
var base_fire: int
var base_ice: int
var base_poison: int
var base_electric: int
var base_crit_damage: int
var base_crit_chance: float
var base_dodge: float

var perm_modifiers := {
	"max_health": 0,
	"damage": 0,
	"elemental_power": 0,
	"fire": 0,
	"ice": 0,
	"poison": 0,
	"electric": 0,
	"crit_damage": 0,
	"crit_chance": 0,
	"dodge": 0
}

@export var luck: float = 0.0 # 0-0.70

# Runtime values
var current_health: int
var energy: int = 3
var max_energy: int = 3

var deck_list : Array[CardData] = []
"""
