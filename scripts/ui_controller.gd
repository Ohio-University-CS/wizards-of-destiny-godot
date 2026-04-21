extends Node

func _ready() -> void:
	await get_tree().process_frame
	_connect_to_manager()
	# Listen for player node changes (reparenting after combat)
	if RunManager.has_signal("player_changed"):
		RunManager.connect("player_changed", Callable(self, "_on_player_changed"), CONNECT_DEFERRED)

func _connect_to_manager() -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return
	
	var temp_combat = scene_root.find_child("TempCombat", true, false)
	var manager = scene_root.find_child("GameManager", true, false)
	
	# -------------------------
	# UI → gameplay buttons
	# -------------------------
	var target = temp_combat if temp_combat != null else manager
	
	if target != null:
		_connect_buttons(target, temp_combat, manager)
	
	# -------------------------
	# UI → player (ALWAYS RUN)
	# -------------------------
	_bind_player_ui(temp_combat)


func _connect_buttons(target, temp_combat, _manager):
	var play_btn = find_child("Play", true, false)
	if play_btn and play_btn.has_signal("play_hand_requested"):
		if not play_btn.is_connected("play_hand_requested", Callable(target, "play_hand")):
			play_btn.connect("play_hand_requested", Callable(target, "play_hand"))

	var end_btn = find_child("EndTurn", true, false)
	if end_btn and end_btn.has_signal("end_turn_requested"):
		if temp_combat and temp_combat.has_method("force_end_player_turn"):
			end_btn.connect("end_turn_requested", Callable(temp_combat, "force_end_player_turn"))

	var disc_btn = find_child("Discard", true, false)
	if disc_btn and disc_btn.has_signal("discard_requested"):
		if temp_combat and temp_combat.has_method("discard_selected_cards"):
			disc_btn.connect("discard_requested", Callable(temp_combat, "discard_selected_cards"))


func _bind_player_ui(temp_combat):
	var player_node = null

	if temp_combat:
		player_node = temp_combat.player
	
	if player_node == null:
		player_node = RunManager.player

	print("Binding UI to player:", player_node)

	var health = find_child("PlayerHealthBar", true, false)
	print("Found health:", health)

	var mana = null
	var energy_sprite = find_child("EnergySprite", true, false)
	if energy_sprite:
	    mana = energy_sprite.find_child("Label", true, false)
	print("Found mana:", mana)

	if health and health.has_method("set_target") and player_node:
		health.set_target(player_node)

	if mana and mana.has_method("set_target") and player_node:
		mana.set_target(player_node)

	if player_node:
		player_node.emit_signal("health_changed", player_node.current_health)
		player_node.emit_signal("energy_changed", player_node.energy, player_node.max_energy)


# Called when the player node is replaced or reparented (after combat)
func _on_player_changed(new_player):
	_bind_player_ui(null)
