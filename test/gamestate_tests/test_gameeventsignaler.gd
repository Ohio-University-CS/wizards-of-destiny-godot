extends GutTest

var TempCombatScript = load("res://scripts/temp_combat.gd")
var ShopScript = load("res://scenes/Shop/shop.gd")

var _combat_end_count := 0
var _next_combat_begin_count := 0
var _first_combat_begin_count := 0

var _last_combat_player: Player = null
var _last_next_player: Player = null
var _test_player: Player = null


func before_each():
	_combat_end_count = 0
	_next_combat_begin_count = 0
	_first_combat_begin_count = 0
	_last_combat_player = null
	_last_next_player = null

	_test_player = Player.new()
	add_child_autofree(_test_player)
	RunManager.player = _test_player

	GameEventSignaler.combat_end.connect(_on_combat_end)
	GameEventSignaler.next_combat_begin.connect(_on_next_combat_begin)
	GameEventSignaler.first_combat_begin.connect(_on_first_combat_begin)


func after_each():
	if GameEventSignaler.combat_end.is_connected(_on_combat_end):
		GameEventSignaler.combat_end.disconnect(_on_combat_end)
	if GameEventSignaler.next_combat_begin.is_connected(_on_next_combat_begin):
		GameEventSignaler.next_combat_begin.disconnect(_on_next_combat_begin)
	if GameEventSignaler.first_combat_begin.is_connected(_on_first_combat_begin):
		GameEventSignaler.first_combat_begin.disconnect(_on_first_combat_begin)

	RunManager.player = null
	_test_player = null


func _reset_counters():
	_combat_end_count = 0
	_next_combat_begin_count = 0
	_first_combat_begin_count = 0
	_last_combat_player = null
	_last_next_player = null


func _make_player() -> Player:
	var player = Player.new()
	add_child_autofree(player)
	return player


func _on_combat_end(player_state: Player):
	_combat_end_count += 1
	_last_combat_player = player_state


func _on_next_combat_begin(player_state: Player):
	_next_combat_begin_count += 1
	_last_next_player = player_state


func _on_first_combat_begin(_player_state: Player):
	_first_combat_begin_count += 1


func test_temp_combat_result_emits_combat_end_once_with_player():
	# Normal case: first win result should emit combat_end once.
	var combat = TempCombatScript.new()
	combat.player = _test_player

	combat._show_result(true)

	assert_eq(_combat_end_count, 1, "Normal case should emit combat_end once")
	assert_eq(_last_combat_player, _test_player, "Normal case should pass active player")

	# Edge case: repeated result call should not emit again because combat is already over.
	combat._show_result(true)
	assert_eq(_combat_end_count, 1, "Edge case repeated result should not emit additional combat_end")

	# Error case: loss result with null player should still emit exactly once with null payload.
	_reset_counters()
	var combat_with_null_player = TempCombatScript.new()
	combat_with_null_player.player = null
	combat_with_null_player._show_result(false)
	assert_eq(_combat_end_count, 1, "Error case should still emit combat_end even with null player")
	assert_eq(_last_combat_player, null, "Error case payload should be null when combat player is missing")

	combat.free()
	combat_with_null_player.free()


func test_shop_next_stage_emits_next_combat_begin_with_runmanager_player():
	# Normal case: leaving shop should emit next_combat_begin once with RunManager.player.
	var shop = ShopScript.new()

	shop._on_next_stage_pressed()

	assert_eq(_next_combat_begin_count, 1, "Normal case should emit next_combat_begin once")
	assert_eq(_last_next_player, _test_player, "Normal case should pass RunManager.player")

	# Edge case: direct signal emit should also be observed by listeners.
	GameEventSignaler.next_combat_begin.emit(_test_player)
	assert_eq(_next_combat_begin_count, 2, "Edge case direct emit should increment next_combat_begin count")

	# Error case: null RunManager.player should still emit signal with null payload.
	_reset_counters()
	RunManager.player = null
	GameEventSignaler.next_combat_begin.emit(RunManager.player)
	assert_eq(_next_combat_begin_count, 1, "Error case should still emit next_combat_begin with null player")
	assert_eq(_last_next_player, null, "Error case payload should be null when RunManager.player is missing")

	shop.free()


func test_shop_next_stage_does_not_emit_first_combat_begin():
	# Normal case: shop exit should not start first combat signal.
	var shop = ShopScript.new()

	shop._on_next_stage_pressed()

	assert_eq(_first_combat_begin_count, 0, "Normal case should not emit first_combat_begin")

	# Edge case: direct next_combat_begin signal should still not trigger first_combat_begin.
	GameEventSignaler.next_combat_begin.emit(_test_player)
	GameEventSignaler.next_combat_begin.emit(_test_player)
	assert_eq(_first_combat_begin_count, 0, "Edge case repeated shop exits should not emit first_combat_begin")

	# Error case: changing player references should still not emit first_combat_begin.
	RunManager.player = _make_player()
	GameEventSignaler.next_combat_begin.emit(RunManager.player)
	assert_eq(_first_combat_begin_count, 0, "Error case player replacement should not emit first_combat_begin")

	shop.free()


func test_manual_first_combat_begin_signal_cases():
	# Normal case: direct emit should increment first_combat_begin listener count.
	GameEventSignaler.first_combat_begin.emit(_test_player)
	assert_eq(_first_combat_begin_count, 1, "Normal manual emit should be received")

	# Edge case: second emit should increment count again.
	GameEventSignaler.first_combat_begin.emit(_test_player)
	assert_eq(_first_combat_begin_count, 2, "Edge second manual emit should increment count")

	# Error case: null payload should still be delivered to listeners.
	GameEventSignaler.first_combat_begin.emit(null)
	assert_eq(_first_combat_begin_count, 3, "Error manual emit with null payload should still be received")


func test_manual_combat_end_signal_cases():
	# Normal case: direct emit with active player should be observed.
	GameEventSignaler.combat_end.emit(_test_player)
	assert_eq(_combat_end_count, 1, "Normal manual combat_end emit should be received")
	assert_eq(_last_combat_player, _test_player, "Normal manual emit should pass player payload")

	# Edge case: direct emit with a different player should update payload.
	var other_player = _make_player()
	GameEventSignaler.combat_end.emit(other_player)
	assert_eq(_combat_end_count, 2, "Edge second manual combat_end emit should increment count")
	assert_eq(_last_combat_player, other_player, "Edge second manual emit should update payload")

	# Error case: null payload should still emit and be observable.
	GameEventSignaler.combat_end.emit(null)
	assert_eq(_combat_end_count, 3, "Error manual emit with null payload should still increment count")
	assert_eq(_last_combat_player, null, "Error manual emit should pass null payload")
