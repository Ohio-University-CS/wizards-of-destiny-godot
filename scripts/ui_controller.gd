extends Node

func _ready() -> void:
	await get_tree().process_frame
	_connect_to_manager()
	#call_deferred("_connect_to_manager")


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

	var mana = find_child("PlayerManaBar", true, false)
	print("Found mana:", mana)

	if health and health.has_method("set_target") and player_node:
		health.set_target(player_node)

	if mana and mana.has_method("set_target") and player_node:
		mana.set_target(player_node)

	if player_node:
		player_node.emit_signal("health_changed", player_node.current_health)
		player_node.emit_signal("energy_changed", player_node.energy, player_node.max_energy)


#
#func _connect_to_manager() -> void:
	#var scene_root = get_tree().current_scene
	#if scene_root == null:
		#return
#
	#var manager = scene_root if scene_root.name == "GameManager" else scene_root.find_child("GameManager", true, false)
	#var temp_combat = scene_root if scene_root.name == "TempCombat" else scene_root.find_child("TempCombat", true, false)
	#var target = temp_combat if temp_combat != null else manager
	##if target == null:
		##return
#
	## Play button
	#var play_btn = null
	#if has_node("PanelContainer/Play"):
		#play_btn = get_node("PanelContainer/Play")
	#elif has_node("Play"):
		#play_btn = get_node("Play")
	#if play_btn != null and play_btn.has_signal("play_hand_requested"):
		#if not play_btn.is_connected("play_hand_requested", Callable(target, "play_hand")):
			#play_btn.connect("play_hand_requested", Callable(target, "play_hand"))
#
	## End turn button
	#var end_btn = get_node_or_null("EndTurn")
	#if end_btn != null and end_btn.has_signal("end_turn_requested"):
		#if temp_combat and temp_combat.has_method("force_end_player_turn"):
			#if not end_btn.is_connected("end_turn_requested", Callable(temp_combat, "force_end_player_turn")):
				#end_btn.connect("end_turn_requested", Callable(temp_combat, "force_end_player_turn"))
		#elif manager and manager.has_method("force_end_player_turn"):
			#if not end_btn.is_connected("end_turn_requested", Callable(manager, "force_end_player_turn")):
				#end_btn.connect("end_turn_requested", Callable(manager, "force_end_player_turn"))
#
	## Discard button
	#var disc_btn = get_node_or_null("Discard")
	#if disc_btn != null and disc_btn.has_signal("discard_requested"):
		#if temp_combat and temp_combat.has_method("discard_selected_cards"):
			#if not disc_btn.is_connected("discard_requested", Callable(temp_combat, "discard_selected_cards")):
				#disc_btn.connect("discard_requested", Callable(temp_combat, "discard_selected_cards"))
		#elif manager and manager.has_method("discard_selected_cards"):
			#if not disc_btn.is_connected("discard_requested", Callable(manager, "discard_selected_cards")):
				#disc_btn.connect("discard_requested", Callable(manager, "discard_selected_cards"))
#
	## Wire health/mana displays to player if possible
	#var player_node = null
	#
	#if temp_combat != null:
		#player_node = temp_combat.player
	#
	#if player_node == null:
		#player_node = RunManager.player
	##if temp_combat and temp_combat.has_variable("player"):
		##player_node = temp_combat.player
	##if player_node == null:
		##player_node = scene_root.get_node_or_null("Player")
		##if player_node == null:
			##player_node = scene_root.find_child("Player", true, false)
#
	##var health = get_node_or_null("PlayerHealth")
	##if health == null:
		##health = get_node_or_null("Player Health")
	#var health = find_child("PlayerHealth", true, false)
	#if health == null:
		#health = find_child("Player Health", true, false)
	#print("Found health node:", health)
	#if health != null:
		#if health.has_method("set_target") and player_node != null:
			#health.set_target(player_node)
		#elif health.has_variable("target_path"):
			#health.target_path = NodePath("../Player")
#
	##var mana = get_node_or_null("PlayerManaBar")
	#var mana = find_child("PlayerManaBar", true, false)
	#if mana != null:
		#if mana.has_method("set_target") and player_node != null:
			#mana.set_target(player_node)
		#elif mana.has_variable("target_path"):
			#mana.target_path = NodePath("../Player")
	#
	#if player_node:
		#if player_node.has_signal("health_changed"):
			#player_node.emit_signal("health_changed", player_node.current_health)
		#
		#if player_node.has_signal("energy_changed"):
			#player_node.emit_signal("energy_changed", player_node.energy, player_node.max_energy)
