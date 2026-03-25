#temp_combat.gd
@tool
extends Node2D

signal turn_changed(turn_name, turn_count)

@onready var player: Player = null
@onready var deck: CombatDeck = null
@onready var opponent: Enemy = null

const DEFAULT_GOBLIN_SCENE_PATH := "res://Enemies/enemy_resources/Goblin/Goblin.tscn"
const DEFAULT_WIZARD_SCENE_PATH := "res://Enemies/enemy_resources/Wizard/Wizard.tscn"

@export var card_scene: PackedScene = null
@export var class_data: ClassData
@export var enemy_pool: Array[PackedScene] = []
@export_range(0.25, 4.0, 0.05) var game_speed: float = 1.0
@export var play_move_duration: float = 0.60
@export var play_fade_duration: float = 0.45
@export var enemy_move_cost: int = 1
@export var enemy_move_base_amount: int = 1
@export var enemy_move_delay: float = 0.35
@export var enemy_spawn_position: Vector2 = Vector2(1458.75, 167.5)
@export var enemy_spawn_scale: Vector2 = Vector2(1.75, 1.75)
@export var player_move_label_path: NodePath = NodePath("PlayerMoveText")
@export var enemy_move_label_path: NodePath = NodePath("EnemyMoveText")
@export var player_name_label_path: NodePath = NodePath("Player/PlayerName")
@export var enemy_name_label_path: NodePath = NodePath("Enemy/EnemyName")
@export var discard_button_path: NodePath = NodePath("PanelContainer/Discard")
@export var result_overlay_path: NodePath = NodePath("ResultCanvas/ResultOverlay")
@export var result_label_path: NodePath = NodePath("ResultCanvas/ResultOverlay/ResultText")
@export var move_text_hold_duration: float = 0.60
@export var move_text_fade_duration: float = 0.40
@export var turn_transition_delay: float = 0.20
@export var hand_origin: Vector2 = Vector2(300, 500)
@export var hand_spacing: float = 180.0
@export var hand_return_duration: float = 0.22

var enemy_intent_1: TextureRect = null
var enemy_intent_2: TextureRect = null
var enemy_intent_3: TextureRect = null

var is_play_animating: bool = false
var player_move_label: Label = null
var enemy_move_label: Label = null
var player_name_label: Label = null
var enemy_name_label: Label = null
var discard_button: Button = null
var result_overlay: ColorRect = null
var result_label: Label = null
var player_move_tween: Tween = null
var enemy_move_tween: Tween = null
var hand_cards: Array = []
var dragged_hand_card: Control = null
var enemy_rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum TurnState {
	PLAYER,
	ENEMY,
	PLAYER_WIN,
	ENEMY_WIN
}

var current_turn: TurnState = TurnState.PLAYER
var turn_count: int = 1
var is_processing_enemy_turn: bool = false
var is_combat_over: bool = false

# Editor preview settings
@export var preview_in_editor: bool = false
@export var preview_count: int = 5


func _ready():
	enemy_rng.randomize()

	#------------------------------
	# use persistent player if possible
	#------------------------------
	if RunManager.player:
		player = RunManager.player
		if player.get_parent():
			player.get_parent().remove_child(player)
			add_child(player)
		
		var ui = find_child("UI", true, false)
		if ui and ui.has_method("_bind_player_ui"):
			ui._bind_player_ui(self)
	
	#-------------------
	# fallback
	#-------------------
	# Locate the player node by common names or by type to avoid null path errors
	if player == null:
		if has_node("Player"):
			var maybe_player = get_node("Player")
			if maybe_player is Player:
				player = maybe_player
			elif maybe_player.has_node("Player") and maybe_player.get_node("Player") is Player:
				player = maybe_player.get_node("Player")
		elif has_node("Player2"):
			var maybe_player2 = get_node("Player2")
			if maybe_player2 is Player:
				player = maybe_player2
			elif maybe_player2.has_node("Player") and maybe_player2.get_node("Player") is Player:
				player = maybe_player2.get_node("Player")
		else:
			for child in get_children():
				if child is Player:
					player = child
					break
	
	#------------------
	# validate
	#------------------
	if player == null:
		push_error("TempCombat: no Player node found")
	else:
		if player.class_data == null:
			player.setup_from_class(class_data)
			player.initialized = true
			
		if player.has_signal("health_changed"):
			player.emit_signal("health_changed", player.current_health)
		if player.has_signal("energy_changed"):
			player.emit_signal("energy_changed", player.energy, player.max_energy)
	
	#keep reference updated
	RunManager.player = player
	
	#------------------------
	# Spawn enemy
	#------------------------
	_spawn_random_enemy_entity()
	
	if opponent == null:
		if has_node("Enemy") and get_node("Enemy") is Enemy:
			opponent = get_node("Enemy")
		elif has_node("Enemy/Enemy") and get_node("Enemy/Enemy") is Enemy:
			opponent = get_node("Enemy/Enemy")
		elif has_node("Sprite2D/Enemy") and get_node("Sprite2D/Enemy") is Enemy:
			opponent = get_node("Sprite2D/Enemy")
		else:
			for child in get_children():
				if child is Enemy:
					opponent = child
					break
			if opponent == null:
				var enemies = find_children("*", "Enemy", true, false)
				if enemies.size() > 0 and enemies[0] is Enemy:
					opponent = enemies[0]
	
	if opponent:
		_position_enemy_container(opponent)
		if opponent.has_signal("health_changed"):
			opponent.emit_signal("health_changed", opponent.current_health)
		if opponent.has_signal("energy_changed"):
			opponent.emit_signal("energy_changed", opponent.energy, opponent.max_energy)
	else:
		push_error("TempCombat: no Enemy node found; cards will not have a valid target")
	
	#------------------
	# Deck setup
	#------------------
	if deck == null:
		if has_node("CombatDeck") and get_node("CombatDeck") is CombatDeck:
			deck = get_node("CombatDeck")
		elif has_node("PanelContainer/CombatDeck") and get_node("PanelContainer/CombatDeck") is CombatDeck:
			deck = get_node("PanelContainer/CombatDeck")
		else:
			for child in get_children():
				if child is CombatDeck:
					deck = child
					break
			if deck == null:
				var combat_decks = find_children("*", "CombatDeck", true, false)
				if combat_decks.size() > 0 and combat_decks[0] is CombatDeck:
					deck = combat_decks[0]
	
	if deck:
		deck.setup_from_player(player)
	else:
		push_error("TempCombat: no CombatDeck found, cannot draw cards")
	
	
	# Initialize enemy intent UI nodes — they may live under the Enemy container or at the scene root
	var _e1 = get_node_or_null("Enemy/EnemyIntent1")
	if _e1 == null:
		_e1 = get_node_or_null("EnemyIntent1")
	if _e1 and _e1 is TextureRect:
		enemy_intent_1 = _e1

	var _e2 = get_node_or_null("Enemy/EnemyIntent2")
	if _e2 == null:
		_e2 = get_node_or_null("EnemyIntent2")
	if _e2 and _e2 is TextureRect:
		enemy_intent_2 = _e2

	var _e3 = get_node_or_null("Enemy/EnemyIntent3")
	if _e3 == null:
		_e3 = get_node_or_null("EnemyIntent3")
	if _e3 and _e3 is TextureRect:
		enemy_intent_3 = _e3
	
	player_move_label = get_node_or_null(player_move_label_path)
	enemy_move_label = get_node_or_null(enemy_move_label_path)

	# Prefer UI-local labels when move text lives in the shared UI scene
	var ui_node = get_node_or_null("UI")
	if ui_node != null:
		# If the UI provides a shared centered MoveText label prefer it for both
		var shared = ui_node.get_node_or_null("MoveText")
		if shared != null:
			player_move_label = shared
			enemy_move_label = shared
		else:
			if player_move_label == null:
				var p_from_ui = ui_node.get_node_or_null(player_move_label_path)
				if p_from_ui != null:
					player_move_label = p_from_ui
			if enemy_move_label == null:
				var e_from_ui = ui_node.get_node_or_null(enemy_move_label_path)
				if e_from_ui != null:
					enemy_move_label = e_from_ui

	# Fallbacks: if exported NodePaths and UI lookup didn't resolve, try searching the scene
	if player_move_label == null:
		# prefer labels that live under the Player node
		if player and player.has_node("PlayerMoveText"):
			player_move_label = player.get_node_or_null("PlayerMoveText")
		else:
			var found_p = find_child("PlayerMoveText", true, false)
			if found_p:
				player_move_label = found_p

	if enemy_move_label == null:
		# prefer labels that live under the UI or Enemy node
		if opponent and opponent.has_node("EnemyMoveText"):
			enemy_move_label = opponent.get_node_or_null("EnemyMoveText")
		else:
			var found_e = find_child("EnemyMoveText", true, false)
			if found_e:
				enemy_move_label = found_e

	# Ensure the labels start invisible (alpha 0) so announce/fade works predictably
	if player_move_label:
		if player_move_label:
			var c = player_move_label.modulate
			c.a = 0.0
			player_move_label.modulate = c

	if enemy_move_label:
		var c2 = enemy_move_label.modulate
		c2.a = 0.0
		enemy_move_label.modulate = c2
	player_name_label = get_node_or_null(player_name_label_path)
	enemy_name_label = get_node_or_null(enemy_name_label_path)
	discard_button = get_node_or_null(discard_button_path)
	result_overlay = get_node_or_null(result_overlay_path)
	result_label = get_node_or_null(result_label_path)
	if result_overlay:
		result_overlay.visible = false
	
	if player and player.has_signal("died"):
		if not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)
	if opponent and opponent.has_signal("died"):
		if not opponent.died.is_connected(_on_opponent_died):
			opponent.died.connect(_on_opponent_died)
	
	if opponent:
		opponent.prepare_next_move()
	
	_update_combatant_name_labels()
	_update_discard_button_state()

	_apply_game_speed_to_ui()

	# Ensure exported scene overrides that were set to `null` get sensible defaults
	if enemy_spawn_position == null:
		enemy_spawn_position = Vector2(1550, 651)
	if hand_origin == null:
		hand_origin = Vector2(500, 750)
	if hand_spacing == null or hand_spacing == 0:
		hand_spacing = 180.0

	# Ensure UI buttons/signals connect to this TempCombat instance when UI is
	# a separate packed scene instanced under this node.
	_connect_ui_signals()

	# -- Editor-time spawn handle: create or sync a Position2D the user can drag --
	if Engine.is_editor_hint():
		var handle = get_node_or_null("EnemySpawnHandle")
		if handle == null:
			handle = Marker2D.new()
			handle.name = "EnemySpawnHandle"
			add_child(handle)
			# make it part of the edited scene so it's visible and movable
			if get_owner() != null:
				handle.owner = get_owner()
		# initialize position
		handle.position = enemy_spawn_position
		# enable processing in editor so _process runs
		set_process(true)
	else:
		set_process(false)


	_start_player_turn()

	# In the editor, create preview cards so you can see them in the scene tree/viewport
	if Engine.is_editor_hint() and preview_in_editor:
		_create_editor_previews()


func _spawn_random_enemy_entity() -> void:
	var pool: Array[PackedScene] = enemy_pool
	if pool.is_empty():
		pool = _get_default_enemy_pool()

	if pool.is_empty():
		push_error("TempCombat: enemy_pool is empty and no default enemy scenes were found")
		return

	var selected_scene := pool[enemy_rng.randi_range(0, pool.size() - 1)]
	if selected_scene == null:
		push_error("TempCombat: selected enemy scene is null")
		return

	var existing_enemy_container := get_node_or_null("Enemy")
	if existing_enemy_container != null:
		if Engine.is_editor_hint():
			# Keep editor-placed preview enemy while editing the scene.
			existing_enemy_container.position = enemy_spawn_position
			if existing_enemy_container is Node2D:
				existing_enemy_container.scale = enemy_spawn_scale
			opponent = _find_enemy_in_container(existing_enemy_container)
			return

		# In gameplay, replace any editor-placed enemy with a random pick.
		remove_child(existing_enemy_container)
		existing_enemy_container.free()

	var spawned_enemy_container := selected_scene.instantiate()
	if not (spawned_enemy_container is Node2D):
		push_error("TempCombat: selected enemy scene root must be Node2D")
		if is_instance_valid(spawned_enemy_container):
			spawned_enemy_container.queue_free()
		return

	spawned_enemy_container.name = "Enemy"
	add_child(spawned_enemy_container)
	spawned_enemy_container.position = enemy_spawn_position
	spawned_enemy_container.scale = enemy_spawn_scale

	opponent = _find_enemy_in_container(spawned_enemy_container)
	if opponent == null:
		push_error("TempCombat: spawned enemy scene does not contain an Enemy script instance")


func _find_enemy_in_container(container: Node) -> Enemy:
	if container is Enemy:
		return container as Enemy

	if container.has_node("Enemy") and container.get_node("Enemy") is Enemy:
		return container.get_node("Enemy") as Enemy

	var candidates := container.find_children("*", "Enemy", true, false)
	for c in candidates:
		if c is Enemy:
			return c

	return null


func _position_enemy_container(enemy: Enemy) -> void:
	var container: Node = enemy
	if enemy.get_parent() != self and enemy.get_parent() is Node2D:
		container = enemy.get_parent()
	if container is Node2D:
		container.position = enemy_spawn_position
		container.scale = enemy_spawn_scale


func _get_default_enemy_pool() -> Array[PackedScene]:
	var defaults: Array[PackedScene] = []
	for path in [DEFAULT_GOBLIN_SCENE_PATH, DEFAULT_WIZARD_SCENE_PATH]:
		if ResourceLoader.exists(path):
			var loaded = load(path)
			if loaded is PackedScene:
				defaults.append(loaded)
	return defaults


#func _enter_tree():
	#if Engine.is_editor_hint() and preview_in_editor:
		#_create_editor_previews()

func _exit_tree():
	if Engine.is_editor_hint():
		_clear_editor_previews()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	# sync handle -> enemy_spawn_position when moved in editor
	var handle = get_node_or_null("EnemySpawnHandle")
	if handle and handle is Marker2D:
		if handle.position != enemy_spawn_position:
			enemy_spawn_position = handle.position
			# move any existing Enemy container in the scene to reflect change
			var existing_enemy = get_node_or_null("Enemy")
			if existing_enemy and existing_enemy is Node2D:
				existing_enemy.position = enemy_spawn_position

	# ensure the handle follows property changes made in the inspector
	if handle and handle is Marker2D:
		if enemy_spawn_position != handle.position:
			handle.position = enemy_spawn_position

func draw_hand():
	if deck == null:
		return
	
	# Spawn visuals for cards already in hand
	for existing_card in deck.hand:
		if not _has_visual_for_instance(existing_card):
			spawn_card(existing_card)
	
	# Draw remaining cards
	while hand_cards.size() < deck.draw_hand_size:
		var card_instance = deck.draw_card()
		if card_instance == null:
			break
		
		spawn_card(card_instance)
	
	_layout_hand(false)


func play_hand() -> void:
	if is_combat_over:
		return
	if is_play_animating or is_processing_enemy_turn:
		return

	if current_turn != TurnState.PLAYER:
		return

	var selected_cards = _get_selected_playable_cards()
	var played_any: bool = false
	if selected_cards.size() > 0 and is_instance_valid(selected_cards[0]):
		played_any = await play_card(selected_cards[0])

	if played_any and not _can_player_continue_turn():
		await _end_player_turn()
	elif not played_any and not _can_player_continue_turn():
		await _end_player_turn()


func force_end_player_turn() -> void:
	if is_combat_over:
		return
	if is_play_animating or is_processing_enemy_turn:
		return
	if current_turn != TurnState.PLAYER:
		return
	await _end_player_turn()


func _get_selected_playable_cards() -> Array:
	var cards: Array = []
	for card in hand_cards:
		if is_instance_valid(card) and bool(card.get("is_selected")):
			cards.append(card)
	return cards

func spawn_card(instance: CardInstance):
	var card = card_scene.instantiate()
	add_child(card)

	card.setup(instance)

	hand_cards.append(card)
	card.position = _slot_position_for_index(hand_cards.size() - 1)

	card.card_clicked.connect(func(): _on_card_clicked(card))
	if card.has_signal("card_drag_started"):
		card.card_drag_started.connect(_on_card_drag_started)
	if card.has_signal("card_drag_moved"):
		card.card_drag_moved.connect(_on_card_drag_moved)
	if card.has_signal("card_drag_released"):
		card.card_drag_released.connect(_on_card_drag_released)
	if card.has_signal("selection_changed"):
		card.selection_changed.connect(_on_card_selection_changed)

	_layout_hand(true)
	_update_discard_button_state()


func _on_card_clicked(card_node) -> void:
	var played: bool = await play_card(card_node)
	if played and not _can_player_continue_turn():
		await _end_player_turn()


func play_card(card_node) -> bool:
	if is_combat_over:
		return false
	if is_play_animating or is_processing_enemy_turn:
		return false
	
	if current_turn != TurnState.PLAYER:
		return false
	
	var instance = card_node.card_instance
	
	if player.energy < instance.data.energy_cost:
		return false
	
	if opponent == null:
		push_error("TempCombat: cannot play card without a valid opponent target")
		return false
	
	# Spend energy + validate play
	if not instance.play(opponent, player):
		return false
	
	# Apply effects
	_apply_effects(instance.data.effects, player)
	
	is_play_animating = true
	_announce_move(true, instance.data.card_name)
	
	if card_node is Control:
		card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if instance.exhausted:
		deck.exhaust_card(instance)
	else:
		deck.discard_card(instance)
	
	hand_cards.erase(card_node)
	_sync_deck_hand_to_visual_order()
	_layout_hand(true)
	_update_discard_button_state()
	
	await _animate_played_card(card_node)
	card_node.queue_free()
	is_play_animating = false
	return true


func _start_player_turn() -> void:
	if is_combat_over:
		return
	current_turn = TurnState.PLAYER
	emit_signal("turn_changed", "PLAYER", turn_count)
	
	update_enemy_intent()
	
	if player:
		player.start_turn()
	draw_hand()


func _end_player_turn() -> void:
	if is_combat_over:
		return
	
	if player:
		player.perform_strike(opponent)
		player.end_turn()
	
	#discard remaining cards
	_discard_hand()
	
	if turn_transition_delay > 0.0:
		await get_tree().create_timer(_scaled_time(turn_transition_delay)).timeout
	
	await _start_enemy_turn()


func _start_enemy_turn() -> void:
	if is_combat_over:
		return
	current_turn = TurnState.ENEMY
	turn_count += 1
	is_processing_enemy_turn = true
	emit_signal("turn_changed", "ENEMY", turn_count)

	clear_enemy_intent()

	if opponent:
		opponent.start_turn()

	await _enemy_take_turn()

	if opponent:
		opponent.end_turn()

	opponent.prepare_next_move()
	
	if turn_transition_delay > 0.0:
		await get_tree().create_timer(_scaled_time(turn_transition_delay)).timeout

	is_processing_enemy_turn = false
	_start_player_turn()


func clear_enemy_intent() -> void:
	if enemy_intent_1:
		enemy_intent_1.texture = null
	if enemy_intent_2:
		enemy_intent_2.texture = null
	if enemy_intent_3:
		enemy_intent_3.texture = null


func update_enemy_intent() -> void:
	if opponent == null:
		return

	var next_move = opponent.get_next_move()
	if next_move == null:
		clear_enemy_intent()
		return

	# set textures only if intent_icons exist and the UI nodes are present
	if next_move.intent_icons.size() > 0 and enemy_intent_1:
		enemy_intent_1.texture = next_move.intent_icons[0]
	elif enemy_intent_1:
		enemy_intent_1.texture = null

	if next_move.intent_icons.size() > 1 and enemy_intent_2:
		enemy_intent_2.texture = next_move.intent_icons[1]
	elif enemy_intent_2:
		enemy_intent_2.texture = null

	if next_move.intent_icons.size() > 2 and enemy_intent_3:
		enemy_intent_3.texture = next_move.intent_icons[2]
	elif enemy_intent_3:
		enemy_intent_3.texture = null


func _enemy_take_turn() -> void:
	if is_combat_over or opponent == null or player == null:
		return
	
	if opponent.is_stunned():
		print("Enemy is stunned")
		return
	
	var move = opponent.current_move
	if move == null:
		move = opponent.select_move()
	
	_announce_move(false, move.name)
	
	_apply_effects(move.effects, opponent)
	
	# handle preventing too many repeat moves
	if move == opponent.last_move:
		opponent.repeat_count += 1
	else:
		opponent.repeat_count = 1
		opponent.last_move = move
	
	if enemy_move_delay > 0.0:
		await get_tree().create_timer(_scaled_time(enemy_move_delay)).timeout


func _apply_effects(effects: Array, source) -> void:
	if effects == null:
		return
	
	# safety checks for valid targets
	if _is_valid_target(source) == false:
		return
	
	for effect in effects:
		if effect == null:
			continue
		
		if randf() > effect.chance:
			continue
		
		var targets = _get_effect_targets(effect, source)
		
		for target in targets:
			if _is_valid_target(target) == false:
				continue
		
			#---------------
			# Tag Handling
			#---------------
		
			if "random_element" in effect.tags:
				var elements = ["burn", "freeze", "shock"]
				effect.status_name = elements[randi() % elements.size()]
		
			if "undodgeable" in effect.tags:
				if target.status_effects.has("evasive"):
					target.status_effects["evasive"] = 0
			
			effect.apply(source, target, self )


func _announce_move(is_player_move: bool, move_name: String) -> void:
	var label: Label = player_move_label if is_player_move else enemy_move_label
	if label == null:
		return

	var prefix := "Player played" if is_player_move else "Enemy played"
	label.text = "%s: %s" % [prefix, move_name]
	label.modulate.a = 1.0

	var tween_to_kill: Tween = player_move_tween if is_player_move else enemy_move_tween
	if tween_to_kill and tween_to_kill.is_valid():
		tween_to_kill.kill()

	var tween: Tween = create_tween()
	tween.tween_interval(max(0.0, _scaled_time(move_text_hold_duration)))
	tween.tween_property(label, "modulate:a", 0.0, _scaled_time(move_text_fade_duration))

	if is_player_move:
		player_move_tween = tween
	else:
		enemy_move_tween = tween


func _animate_played_card(card_node) -> void:
	if not is_instance_valid(card_node):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var target_position: Vector2 = (viewport_size * 0.5) - (card_node.size * 0.5)

	card_node.z_index = 200

	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card_node, "global_position", target_position, _scaled_time(play_move_duration))
	tween.parallel().tween_property(card_node, "modulate:a", 0.0, _scaled_time(play_fade_duration))

	await tween.finished


func _is_valid_target(target) -> bool:
	return target != null and is_instance_valid(target)


func _get_effect_targets(effect: Effect, source) -> Array:
	var targets: Array = []
	
	match effect.target_type:
		Effect.TargetType.SELF:
			targets.append(source)
		
		Effect.TargetType.ENEMY:
			targets.append(_get_opponent(source))
	
	return targets

# helper function
func _get_opponent(source):
	if source == player:
		return opponent
	return player


func _can_player_continue_turn() -> bool:
	if current_turn != TurnState.PLAYER:
		return false
	if player == null or deck == null:
		return false

	if player.energy <= 0:
		return false

	for card_instance in deck.hand:
		if card_instance and card_instance.data and card_instance.data.energy_cost <= player.energy:
			return true

	return false


func _scaled_time(base_duration: float) -> float:
	return base_duration / max(0.01, game_speed)

func _apply_game_speed_to_ui() -> void:
	var ui_nodes = find_children("*", "ProgressBar", true, false)
	for ui_node in ui_nodes:
		if ui_node.get("game_speed") != null:
			ui_node.set("game_speed", game_speed)


func _connect_ui_signals() -> void:
	var ui = get_node_or_null("UI")
	if ui == null:
		ui = find_child("UI", true, false)
	if ui == null:
		return

	# Play button
	var play_btn = ui.get_node_or_null("PanelContainer/Play") if ui.has_node("PanelContainer/Play") else ui.get_node_or_null("Play")
	if play_btn != null and play_btn.has_signal("play_hand_requested"):
		if not play_btn.is_connected("play_hand_requested", Callable(self , "play_hand")):
			play_btn.connect("play_hand_requested", Callable(self , "play_hand"))

	# End turn button
	var end_btn = ui.get_node_or_null("EndTurn")
	if end_btn != null and end_btn.has_signal("end_turn_requested"):
		if not end_btn.is_connected("end_turn_requested", Callable(self , "force_end_player_turn")):
			end_btn.connect("end_turn_requested", Callable(self , "force_end_player_turn"))

	# Discard button
	var disc_btn = ui.get_node_or_null("Discard")
	if disc_btn != null and disc_btn.has_signal("discard_requested"):
		if not disc_btn.is_connected("discard_requested", Callable(self , "discard_selected_cards")):
			disc_btn.connect("discard_requested", Callable(self , "discard_selected_cards"))
	# Player Health Bar
	var health_bar = ui.get_node_or_null("PlayerHealth")
	if health_bar and health_bar.has_method("set_target") == false and health_bar.has_variable("target_path"):
		# ensure the NodePath points to the sibling Player
		health_bar.target_path = NodePath("../Player")
		#health_bar.set_target(player)
	# Mana Indicator
	var mana_bar = ui.get_node_or_null("PlayerManaBar")
	if mana_bar and mana_bar.has_method("set_target") == false and mana_bar.has_variable("target_path"):
		mana_bar.target_path = NodePath("../Player")
	# Damage/Heal Indicator
	var _player_health_indicator = player.get_node_or_null("HealthIndicator")
		

func _on_player_died() -> void:
	_show_result(false)


func _on_opponent_died() -> void:
	_show_result(true)
	
	#detach player so it doesn't get freed
	if player:
		if player.get_parent():
			player.get_parent().remove_child(player)
		get_tree().root.add_child(player)
		RunManager.player = player
	
	# Build result data
	var result = {
		"coins": 12,
		"turns": turn_count,
		"perfect": player.current_health == player.get_max_health()
	}
	
	await get_tree().create_timer(1.5).timeout
	
	FlowManager.on_combat_finished(result)


func _show_result(player_won: bool) -> void:
	if is_combat_over:
		return

	is_combat_over = true
	is_processing_enemy_turn = false
	current_turn = TurnState.PLAYER_WIN if player_won else TurnState.ENEMY_WIN

	if result_overlay:
		result_overlay.visible = true

	if result_label:
		if player_won:
			result_label.text = "You Win!"
			result_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
		else:
			result_label.text = "You Lose!"
			result_label.modulate = Color(1.0, 0.2, 0.2, 1.0)

	_update_discard_button_state()


func _discard_hand():
	if deck == null:
		return
	
	for card in hand_cards:
		if is_instance_valid(card):
			var instance: CardInstance = card.get("card_instance")
			if instance:
				deck.discard_card(instance)
			card.queue_free()
	
	hand_cards.clear()
	deck.hand.clear()


func discard_selected_cards() -> void:
	if is_combat_over or is_play_animating or is_processing_enemy_turn:
		return
	if current_turn != TurnState.PLAYER:
		return
	if deck == null:
		return

	var selected_cards: Array = _get_selected_playable_cards()
	if selected_cards.is_empty():
		return

	for card in selected_cards:
		if not is_instance_valid(card):
			continue

		var instance: CardInstance = card.get("card_instance")
		if instance:
			deck.discard_card(instance)

		hand_cards.erase(card)
		card.queue_free()

	var slots_to_fill: int = max(0, deck.max_hand_size - deck.hand.size())
	for i in range(slots_to_fill):
		var drawn: CardInstance = deck.draw_card()
		if drawn:
			spawn_card(drawn)

	_sync_deck_hand_to_visual_order()
	_layout_hand(true)
	_update_discard_button_state()


func _on_card_drag_started(card: Control) -> void:
	if is_combat_over or current_turn != TurnState.PLAYER:
		return
	dragged_hand_card = card


func _on_card_drag_moved(card: Control) -> void:
	if dragged_hand_card != card:
		return
	_reorder_hand_by_drag_position(card)


func _on_card_drag_released(card: Control) -> void:
	if dragged_hand_card == card:
		dragged_hand_card = null
	_sync_deck_hand_to_visual_order()
	_layout_hand(true)
	_update_discard_button_state()


func _on_card_selection_changed(_card: Control, _selected: bool) -> void:
	_update_discard_button_state()


func _reorder_hand_by_drag_position(card: Control) -> void:
	var old_index: int = hand_cards.find(card)
	if old_index == -1:
		return

	var new_index: int = _get_drag_insert_index(card)
	if new_index == old_index:
		return

	hand_cards.remove_at(old_index)
	hand_cards.insert(new_index, card)
	_sync_deck_hand_to_visual_order()
	_layout_hand(true, card)


func _get_drag_insert_index(card: Control) -> int:
	var drag_center_x: float = card.global_position.x + (card.size.x * 0.5)
	var new_index: int = 0

	for other in hand_cards:
		if other == card:
			continue
		var other_center_x: float = other.global_position.x + (other.size.x * 0.5)
		if drag_center_x > other_center_x:
			new_index += 1

	return clamp(new_index, 0, max(0, hand_cards.size() - 1))


func _layout_hand(animated: bool, skip_card: Control = null) -> void:
	for i in range(hand_cards.size()):
		var card = hand_cards[i]
		if not is_instance_valid(card):
			continue

		var slot_position: Vector2 = _slot_position_for_index(i)
		if animated and card.has_method("animate_to_slot") and card != skip_card:
			card.animate_to_slot(slot_position, _scaled_time(hand_return_duration))
		elif card != skip_card:
			card.position = slot_position
			if card.get("rest_position") != null:
				card.set("rest_position", slot_position)


func _slot_position_for_index(index: int) -> Vector2:
	return Vector2(hand_origin.x + (hand_spacing * index), hand_origin.y)


func _has_visual_for_instance(instance: CardInstance) -> bool:
	for card in hand_cards:
		if is_instance_valid(card) and card.get("card_instance") == instance:
			return true
	return false


func _sync_deck_hand_to_visual_order() -> void:
	if deck == null:
		return

	var reordered: Array[CardInstance] = []
	for card in hand_cards:
		if is_instance_valid(card):
			var instance: CardInstance = card.get("card_instance")
			if instance:
				reordered.append(instance)

	deck.hand = reordered


func _update_enemy_intent():
	if opponent == null or enemy_move_label == null:
		return
	
	if opponent.current_move:
		enemy_move_label.text = "Intent: " + opponent.current_move.name


func _update_combatant_name_labels() -> void:
	if player_name_label:
		player_name_label.text = "Player"

	if enemy_name_label:
		var enemy_type_name: String = "Enemy"
		if opponent and opponent.resource:
			enemy_type_name = opponent.resource.enemy_name
		enemy_name_label.text = enemy_type_name


func _update_discard_button_state() -> void:
	if discard_button == null:
		return

	var can_discard: bool = (not is_combat_over) and (current_turn == TurnState.PLAYER) and (_get_selected_playable_cards().size() > 0)
	discard_button.disabled = not can_discard


func _create_editor_previews():
	_clear_editor_previews()
	if not card_scene:
		return

	for i in range(preview_count):
		var c = card_scene.instantiate()
		c.name = "preview_card_%d" % i
		# Add as child and make it part of the edited scene so editor shows it
		add_child(c)
		if get_owner() != null:
			c.owner = get_owner()
		# Mark as editor-only so it won't affect runtime scenes
		c.editor_only = true
		# Position them for visibility
		c.position = Vector2(200 + i * hand_spacing, 500)


func _clear_editor_previews():
	var to_remove := []
	for child in get_children():
		if typeof(child.name) == TYPE_STRING and child.name.begins_with("preview_card_"):
			to_remove.append(child)
	for c in to_remove:
		if is_instance_valid(c):
			c.queue_free()
