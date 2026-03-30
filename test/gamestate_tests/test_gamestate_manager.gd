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
		if _test_scene.get_parent():
			_test_scene.get_parent().remove_child(_test_scene)
		_test_scene.free()
	_test_scene = Node.new()
	_test_scene.name = scene_name
	get_tree().root.add_child(_test_scene)
	get_tree().current_scene = _test_scene


func _assert_gamestate(expected_player: Player, expected_coins: int, expected_stage: int, expected_floor: int, label: String):
	assert_eq(_gsm.gamestate_player, expected_player, label + " player")
	assert_eq(_gsm.gamestate_coins, expected_coins, label + " coins")
	assert_eq(_gsm.gamestate_stage, expected_stage, label + " stage")
	assert_eq(_gsm.gamestate_level_floor, expected_floor, label + " floor")


func test_scene_change_to_arena_updates_state():
	# Normal case: entering Arena should sync state from RunManager.
	RunManager.player = _make_player()
	RunManager.coins = 77
	RunManager.stage = 3
	RunManager.level_floor = 2
	_set_current_scene("Arena")

	_gsm._on_scene_change()

	_assert_gamestate(RunManager.player, 77, 3, 2, "Normal case should sync")

	# Edge case: zero values should still sync correctly.
	RunManager.player = _make_player()
	RunManager.coins = 0
	RunManager.stage = 0
	RunManager.level_floor = 0
	_set_current_scene("Arena")

	_gsm._on_scene_change()

	_assert_gamestate(RunManager.player, 0, 0, 0, "Edge case should sync zeros")

	# Error case: non-Arena scenes should not update gamestate.
	_gsm.gamestate_coins = 5
	_gsm.gamestate_stage = 9
	_gsm.gamestate_level_floor = 4
	var sentinel_player = _gsm.gamestate_player
	RunManager.player = _make_player()
	RunManager.coins = 101
	RunManager.stage = 8
	RunManager.level_floor = 7
	_set_current_scene("Shop")

	_gsm._on_scene_change()

	_assert_gamestate(sentinel_player, 5, 9, 4, "Error case should not sync non-Arena scene")


func test_enter_shop_scene_change_does_not_update_state():
	# Normal case: entering Shop should not update current gamestate.
	_gsm.gamestate_coins = 5
	_gsm.gamestate_stage = 8
	_gsm.gamestate_level_floor = 3
	var base_player = _gsm.gamestate_player
	RunManager.player = _make_player()
	RunManager.coins = 99
	RunManager.stage = 4
	RunManager.level_floor = 6
	_set_current_scene("Shop")

	_gsm._on_scene_change()

	_assert_gamestate(base_player, 5, 8, 3, "Normal Shop case should not sync")

	# Edge case: an unknown scene name should also not update.
	_gsm.gamestate_coins = 6
	_gsm.gamestate_stage = 10
	_gsm.gamestate_level_floor = 11
	var edge_player = _gsm.gamestate_player
	RunManager.player = _make_player()
	RunManager.coins = 1
	RunManager.stage = 2
	RunManager.level_floor = 12
	_set_current_scene("LevelSelect")

	_gsm._on_scene_change()

	_assert_gamestate(edge_player, 6, 10, 11, "Edge unknown scene should not sync")

	# Error case: malformed scene name should not update.
	_gsm.gamestate_coins = 42
	_gsm.gamestate_stage = 7
	_gsm.gamestate_level_floor = 9
	var err_player = _gsm.gamestate_player
	RunManager.player = _make_player()
	RunManager.coins = 200
	RunManager.stage = 12
	RunManager.level_floor = 10
	_set_current_scene("@@InvalidScene@@")

	_gsm._on_scene_change()

	_assert_gamestate(err_player, 42, 7, 9, "Error malformed scene name should not sync")
	
func test_on_combat_end_updates_state():
	# Normal case: valid player should trigger gamestate sync.
	RunManager.player = _make_player()
	RunManager.coins = 42
	RunManager.stage = 6
	RunManager.level_floor = 3

	_gsm._on_combat_end(RunManager.player)

	_assert_gamestate(RunManager.player, 42, 6, 3, "Normal combat end should sync")

	# Edge case: zero values with valid player should still sync.
	RunManager.player = _make_player()
	RunManager.coins = 0
	RunManager.stage = 0
	RunManager.level_floor = 0

	_gsm._on_combat_end(RunManager.player)

	_assert_gamestate(RunManager.player, 0, 0, 0, "Edge combat end should sync zeros")

	# Error case: null player should not update gamestate.
	_gsm.gamestate_coins = 19
	_gsm.gamestate_stage = 2
	_gsm.gamestate_level_floor = 8
	var sentinel = _gsm.gamestate_player
	RunManager.player = _make_player()
	RunManager.coins = 300
	RunManager.stage = 9
	RunManager.level_floor = 9

	_gsm._on_combat_end(null)

	_assert_gamestate(sentinel, 19, 2, 8, "Error combat end null player should not sync")


func test_exit_shop_signal_updates_state():
	# Normal case: exit shop should sync values.
	RunManager.player = _make_player()
	RunManager.coins = 64
	RunManager.stage = 5
	RunManager.level_floor = 9

	_gsm._on_exit_shop()

	_assert_gamestate(RunManager.player, 64, 5, 9, "Normal exit shop should sync")

	# Edge case: method should accept optional player argument and still sync.
	RunManager.player = _make_player()
	RunManager.coins = 1
	RunManager.stage = 1
	RunManager.level_floor = 1

	_gsm._on_exit_shop(RunManager.player)

	_assert_gamestate(RunManager.player, 1, 1, 1, "Edge optional player arg should sync")

	# Error case: missing RunManager.player should not crash and should store null player.
	RunManager.player = null
	RunManager.coins = 15
	RunManager.stage = 4
	RunManager.level_floor = 2

	_gsm._on_exit_shop(null)

	_assert_gamestate(null, 15, 4, 2, "Error null RunManager.player should still sync values")


func test_write_out_gamestate_returns_true():
	# Normal case: write should return true with typical populated data.
	RunManager.player = _make_player()
	RunManager.coins = 33
	_gsm._update_current_gamestate()
	assert_true(_gsm._write_out_gamestate(), "Normal write should return true")

	# Edge case: write should return true when values are zero.
	RunManager.coins = 0
	RunManager.stage = 0
	RunManager.level_floor = 0
	_gsm._update_current_gamestate()
	assert_true(_gsm._write_out_gamestate(), "Edge write with zeros should return true")

	# Error case: write should still return true when player is null.
	RunManager.player = null
	_gsm._update_current_gamestate()
	assert_true(_gsm._write_out_gamestate(), "Error write with null player should return true")
