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


func _on_combat_end(player_state: Player):
	_combat_end_count += 1
	_last_combat_player = player_state


func _on_next_combat_begin(player_state: Player):
	_next_combat_begin_count += 1
	_last_next_player = player_state


func _on_first_combat_begin(_player_state: Player):
	_first_combat_begin_count += 1


func test_temp_combat_result_emits_combat_end_once_with_player():
	var combat = TempCombatScript.new()
	combat.player = _test_player

	combat._show_result(true)
	combat._show_result(true)

	assert_eq(_combat_end_count, 1, "combat_end should fire once when combat result is first shown")
	assert_eq(_last_combat_player, _test_player, "combat_end should pass the current combat player")
	assert_eq(_next_combat_begin_count, 0, "combat_end flow should not emit next_combat_begin")


func test_shop_next_stage_emits_next_combat_begin_with_runmanager_player():
	var shop = ShopScript.new()

	shop._on_next_stage_pressed()

	assert_eq(_next_combat_begin_count, 1, "next_combat_begin should fire when leaving shop")
	assert_eq(_last_next_player, _test_player, "next_combat_begin should pass RunManager.player")


func test_shop_next_stage_does_not_emit_first_combat_begin():
	var shop = ShopScript.new()

	shop._on_next_stage_pressed()

	assert_eq(_first_combat_begin_count, 0, "first_combat_begin should not fire when exiting shop")
