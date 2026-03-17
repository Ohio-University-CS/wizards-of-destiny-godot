extends ProgressBar

@export var target_path: NodePath
@export var show_mana_text: bool = true

var target: Node = null


func _ready() -> void:
	_assign_target_from_path()
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
	if target_path == NodePath(""):
		return

	var found_target: Node = get_node_or_null(target_path)
	if found_target:
		set_target(found_target)


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
