# mana bar
extends Label

@export var target_path: NodePath
@export var show_mana_text: bool = true

var target: Node = null



func _ready() -> void:
	# Defer target assignment so the parent scene can finish instancing
	# ...existing code...
	call_deferred("_assign_target_from_path")
	call_deferred("_refresh")


func _exit_tree() -> void:
	_disconnect_target_signal()


func set_target(new_target: Node) -> void:
	if target == new_target:
		return

	_disconnect_target_signal()
	target = new_target
	_connect_target_signal()
	_refresh()


func _assign_target_from_path() -> void:
	# If a target path is explicitly provided, try resolving it first.
	if target_path != NodePath(""):
		var found_target: Node = get_node_or_null(target_path)
		if found_target:
			set_target(found_target)
			return

	# Walk up the parent chain to find a Player or Enemy node (useful
	# when this bar is a child of the combatant node).
	var p = get_parent()
	while p != null:
		if p is Player:
			set_target(p)
			return
		p = p.get_parent()

	# As a last resort, search the current scene for a Player node.
	var root = get_tree().current_scene
	if root != null:
		var found := root.find_child("Player", true, false)
		if found != null:
			set_target(found)
			return


func _connect_target_signal() -> void:
	if target == null:
		return

	if target.has_signal("energy_changed"):
		var callback := Callable(self , "_on_energy_changed")
		if not target.is_connected("energy_changed", callback):
			target.connect("energy_changed", callback)


func _disconnect_target_signal() -> void:
	if target == null:
		return

	if target.has_signal("energy_changed"):
		var callback := Callable(self , "_on_energy_changed")
		if target.is_connected("energy_changed", callback):
			target.disconnect("energy_changed", callback)


func _on_energy_changed(_new_value: int, _max_value: int) -> void:
	_refresh()


func _refresh() -> void:
	var current: int = _get_energy_value()
	var max_mana: int = max(1, _get_max_energy_value())
	var display_value = clamp(current, 0, max_mana)

	if show_mana_text:
		text = "%d/%d" % [display_value, max_mana]
	else:
		text = ""



func _get_energy_value() -> int:
	if target == null:
		return 3

	var raw: Variant = target.get("energy")
	if raw == null:
		return _get_max_energy_value()
	return int(raw)


func _get_max_energy_value() -> int:
	if target == null:
		return 3

	var raw: Variant = target.get("max_energy")
	if raw == null:
		return 3
	return int(raw)
