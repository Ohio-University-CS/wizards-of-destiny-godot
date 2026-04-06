# mana bar
extends ProgressBar

@export var target_path: NodePath
@export var show_mana_text: bool = true

var target: Node = null
var fraction_label: Label = null


func _ready() -> void:
	# Defer target assignment so the parent scene can finish instancing
	_ensure_fraction_label()
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
			_update_bar_text(3, 3)
		return

	var current: int = _get_energy_value()
	var max_mana: int = max(1, _get_max_energy_value())

	max_value = max_mana
	value = clamp(current, 0, max_mana)

	if show_mana_text:
		tooltip_text = "%d / %d" % [int(value), int(max_value)]
		_update_bar_text(int(value), int(max_value))


func _update_bar_text(current: int, max_mana: int) -> void:
	var fraction_text: String = "%d / %d" % [current, max_mana]
	var props: Array = get_property_list()
	var names: Array = []
	for p in props:
		names.append(p.name)

	if "show_percentage" in names:
		set("show_percentage", false)
	if "percent_visible" in names:
		set("percent_visible", false)

	_ensure_fraction_label()
	if fraction_label != null:
		fraction_label.visible = show_mana_text
		fraction_label.text = fraction_text


func _ensure_fraction_label() -> void:
	if fraction_label != null and is_instance_valid(fraction_label):
		return

	var existing: Node = get_node_or_null("ManaFractionLabel")
	if existing is Label:
		fraction_label = existing as Label
		return

	var label := Label.new()
	label.name = "ManaFractionLabel"
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set("theme_override_colors/font_color", Color(1, 1, 1, 1))
	label.set("theme_override_colors/font_outline_color", Color(0, 0, 0, 1))
	label.set("theme_override_constants/outline_size", 2)
	add_child(label)
	fraction_label = label


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
