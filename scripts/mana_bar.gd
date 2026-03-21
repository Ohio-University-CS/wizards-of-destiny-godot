extends ProgressBar

@export var target_path: NodePath
@export var show_mana_text: bool = true

var target: Node = null


func _ready() -> void:
	# Defer target assignment so the parent scene can finish instancing
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
	min_value = 0
	max_value = 3

	if target == null:
		value = 3
		if show_mana_text:
			tooltip_text = "3 / 3"
		return

	var current: int = _get_energy_value()
	var max_mana: int = clamp(_get_max_energy_value(), 1, 3)

	max_value = max_mana
	value = clamp(current, 0, max_mana)

	if show_mana_text:
		tooltip_text = "%d / %d" % [int(value), int(max_value)]
		_update_bar_text(int(value), int(max_value))


func _update_bar_text(current: int, max_mana: int) -> void:
	# Try to set a fraction-style text on the ProgressBar itself.
	# Different Godot versions expose different properties, so inspect available properties
	# and set the most appropriate one. Always keep tooltip as a fallback.
	var fraction_text: String = "%d / %d" % [current, max_mana]
	var props: Array = get_property_list()
	var names: Array = []
	for p in props:
		names.append(p.name)

	# Preferred: set a custom text property if present
	if "custom_text" in names:
		set("custom_text", fraction_text)
		if "custom_text_visible" in names:
			set("custom_text_visible", true)
		return

	# Older API: hide percent display if possible and set text override
	if "percent_visible" in names:
		set("percent_visible", false)
		# some versions provide a `text` property to override display
		if "text" in names:
			set("text", fraction_text)
		return

	if "show_percent" in names:
		set("show_percent", false)
		if "text" in names:
			set("text", fraction_text)
		return

	# Last resort: try generic `text` property
	if "text" in names:
		set("text", fraction_text)
		return


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
