extends GutTest

var GSM_Script = load("res://00_globals/GameStateManager.gd")
var _gsm = null
var _test_scene: Node = null

func before_each():
	_gsm = GSM_Script.new()
	add_child_autofree(_gsm)
	_reset_run_manager_state()
	_gsm.gamestate_player = RunManager.player

func after_each():
	if is_instance_valid(_test_scene):
		_test_scene.queue_free()
	_test_scene = null
	_gsm = null


func _reset_run_manager_state():
	RunManager.player = _make_player()
	RunManager.coins = 10
	RunManager.stage = 1
	RunManager.level_floor = 1
	RunManager.item_inventory = []


func _make_player() -> Player:
	var player = Player.new()
	add_child_autofree(player)
	return player


func _set_current_scene(scene_name: String):
	if is_instance_valid(_test_scene):
		_test_scene.queue_free()
	_test_scene = Node.new()
	_test_scene.name = scene_name
	get_tree().root.add_child(_test_scene)
	get_tree().current_scene = _test_scene


func test_scene_change_to_arena_updates_state():
	RunManager.player = _make_player()
	RunManager.coins = 77
	RunManager.stage = 3
	RunManager.level_floor = 2
	_set_current_scene("Arena")

	_gsm._on_scene_change()

	assert_eq(_gsm.gamestate_player, RunManager.player, "Arena scene change should sync player")
	assert_eq(_gsm.gamestate_coins, 77, "Arena scene change should sync coins")
	assert_eq(_gsm.gamestate_stage, 3, "Arena scene change should sync stage")
	assert_eq(_gsm.gamestate_level_floor, 2, "Arena scene change should sync floor")


func test_enter_shop_scene_change_does_not_update_state():
	RunManager.player = _make_player()
	_gsm.gamestate_coins = 5
	_gsm.gamestate_stage = 8
	RunManager.coins = 99
	RunManager.stage = 4
	_set_current_scene("Shop")

	_gsm._on_scene_change()

	assert_eq(_gsm.gamestate_coins, 5, "Non-Arena scene change should not sync coins")
	assert_eq(_gsm.gamestate_stage, 8, "Non-Arena scene change should not sync stage")
	
func test_on_combat_end_updates_state():
	RunManager.player = _make_player()
	RunManager.coins = 42
	RunManager.stage = 6
	RunManager.level_floor = 3

	_gsm._on_combat_end(RunManager.player)

	assert_eq(_gsm.gamestate_player, RunManager.player, "Combat end should sync player data")
	assert_eq(_gsm.gamestate_coins, 42, "Combat end should sync coins")
	assert_eq(_gsm.gamestate_stage, 6, "Combat end should sync stage")
	assert_eq(_gsm.gamestate_level_floor, 3, "Combat end should sync floor")


func test_exit_shop_signal_updates_state():
	RunManager.player = _make_player()
	RunManager.coins = 64
	RunManager.stage = 5
	RunManager.level_floor = 9

	_gsm._on_exit_shop()

	assert_eq(_gsm.gamestate_player, RunManager.player, "Exit shop should sync player data")
	assert_eq(_gsm.gamestate_coins, 64, "Exit shop should sync coins")
	assert_eq(_gsm.gamestate_stage, 5, "Exit shop should sync stage")
	assert_eq(_gsm.gamestate_level_floor, 9, "Exit shop should sync floor")
