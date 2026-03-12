extends Node2D

signal hand_play_requested
signal turn_changed(turn_name, turn_count)

@onready var player: Node = get_node_or_null("Player")
@onready var enemy: Node = get_node_or_null("Enemy")
@onready var card: Node = null

@export_range(0.25, 4.0, 0.05) var game_speed: float = 1.0
@export var player_move_cost: int = 1
@export var enemy_move_cost: int = 1
@export var enemy_move_base_amount: int = 1
@export var enemy_move_delay: float = 0.35
@export var turn_transition_delay: float = 0.20
@export var player_fallback_attack: int = 1
@export var enemy_fallback_attack: int = 1
@export var enemy_fallback_max_health: int = 100

var enemy_fallback_current_health: int = 100

enum TurnState {
	PLAYER,
	ENEMY
}

var current_turn: TurnState = TurnState.PLAYER
var turn_count: int = 1
var is_processing_enemy_turn: bool = false

func _ready():
	card = get_node_or_null("Card")
	if card == null:
		card = get_node_or_null("UI/available_moves/HBoxContainer/card")

	enemy_fallback_current_health = enemy_fallback_max_health

	if card and card.has_signal("card_clicked"):
		card.card_clicked.connect(_on_player_move_requested)

	_start_player_turn()


func play_hand() -> void:
	hand_play_requested.emit()
	_on_player_move_requested()


func force_end_player_turn() -> void:
	if current_turn != TurnState.PLAYER or is_processing_enemy_turn:
		return
	await _end_player_turn()


func _on_player_move_requested() -> void:
	if current_turn != TurnState.PLAYER or is_processing_enemy_turn:
		return

	var played: bool = _player_attack()
	if played and not _can_player_continue_turn():
		await _end_player_turn()
	elif not played:
		await _end_player_turn()


func _player_attack() -> bool:
	if player == null or enemy == null:
		return false

	if player.has_method("spend_energy"):
		if not player.spend_energy(player_move_cost):
			return false

	var damage: int = player_fallback_attack
	if player.has_method("deal_damage"):
		damage = player.deal_damage(player_fallback_attack)

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	else:
		enemy_fallback_current_health = max(0, enemy_fallback_current_health - damage)

	return true


func _start_player_turn() -> void:
	current_turn = TurnState.PLAYER
	emit_signal("turn_changed", "PLAYER", turn_count)
	if player and player.has_method("start_turn"):
		player.start_turn()


func _end_player_turn() -> void:
	if player and player.has_method("end_turn"):
		player.end_turn()
	if turn_transition_delay > 0.0:
		await get_tree().create_timer(_scaled_time(turn_transition_delay)).timeout
	await _start_enemy_turn()


func _start_enemy_turn() -> void:
	current_turn = TurnState.ENEMY
	turn_count += 1
	is_processing_enemy_turn = true
	emit_signal("turn_changed", "ENEMY", turn_count)

	if enemy and enemy.has_method("start_turn"):
		enemy.start_turn()

	await _enemy_take_turn()

	if enemy and enemy.has_method("end_turn"):
		enemy.end_turn()

	if turn_transition_delay > 0.0:
		await get_tree().create_timer(_scaled_time(turn_transition_delay)).timeout

	is_processing_enemy_turn = false
	_start_player_turn()


func _enemy_take_turn() -> void:
	if enemy == null or player == null:
		return

	if not player.has_method("take_damage"):
		return

	var acted: bool = false
	while enemy.has_method("spend_energy") and int(enemy.get("energy")) >= enemy_move_cost and _is_player_alive():
		if not enemy.spend_energy(enemy_move_cost):
			break

		var damage: int = enemy_fallback_attack
		if enemy.has_method("deal_damage"):
			damage = enemy.deal_damage(enemy_move_base_amount)
		player.take_damage(damage)
		acted = true

		if enemy_move_delay > 0.0:
			await get_tree().create_timer(_scaled_time(enemy_move_delay)).timeout

	if not acted and enemy_move_cost <= 0:
		var fallback_damage: int = enemy_fallback_attack
		if enemy.has_method("deal_damage"):
			fallback_damage = enemy.deal_damage(enemy_move_base_amount)
		player.take_damage(fallback_damage)


func _is_player_alive() -> bool:
	if player == null:
		return false
	if player.get("current_health") == null:
		return true
	return int(player.get("current_health")) > 0


func _can_player_continue_turn() -> bool:
	if current_turn != TurnState.PLAYER or player == null:
		return false

	if player.has_method("spend_energy"):
		var current_energy: int = int(player.get("energy"))
		return current_energy >= player_move_cost

	return true


func _scaled_time(base_duration: float) -> float:
	return base_duration / max(0.01, game_speed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
