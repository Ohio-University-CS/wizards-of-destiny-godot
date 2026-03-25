# ui controller
extends Node

var strike_label = null

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
	if temp_combat and temp_combat.player:
		player_node = temp_combat.player
	else:
		player_node = RunManager.player

	var health = find_child("PlayerHealthBar", true, false)
	var mana = find_child("PlayerManaBar", true, false)
	self.strike_label = find_child("StrikeDamageLabel", true, false)

	# Health UI: connect and update
	if health and health.has_method("set_target") and player_node:
		health.set_target(player_node)
		if player_node.is_connected("health_changed", Callable(health, "_on_health_changed")):
			player_node.disconnect("health_changed", Callable(health, "_on_health_changed"))
		player_node.connect("health_changed", Callable(health, "_on_health_changed"))
		# Immediately update health UI
		if health.has_method("_on_health_changed"):
			health._on_health_changed(player_node.current_health)

		   # Mana UI: connect and update
	if mana and mana.has_method("set_target") and player_node:
		mana.set_target(player_node)
		if player_node.is_connected("energy_changed", Callable(mana, "_on_energy_changed")):
			player_node.disconnect("energy_changed", Callable(mana, "_on_energy_changed"))
		player_node.connect("energy_changed", Callable(mana, "_on_energy_changed"))
		# Immediately update mana UI
		if mana.has_method("_on_energy_changed"):
			mana._on_energy_changed(player_node.energy, player_node.max_energy)

	# Strike UI: connect and update
	if self.strike_label and player_node:
		var callable = Callable(self, "_on_strike_changed")
		if player_node.is_connected("strike_changed", callable):
			player_node.disconnect("strike_changed", callable)
		player_node.connect("strike_changed", callable)
		# Immediately update the UI to reflect the current strike value
		_on_strike_changed(player_node.get_damage() + player_node.strike_bonus_damage)


func _on_strike_changed(total):
	if self.strike_label:
		self.strike_label.text = str(total)
