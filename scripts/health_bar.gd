extends ProgressBar

@export var target_path: NodePath
@export_range(0.25, 4.0, 0.05) var game_speed: float = 1.0
@export var show_health_text: bool = true
@export var show_damage_delta: bool = true
@export var damage_text_hold_duration: float = 0.45
@export var damage_text_fade_duration: float = 0.45
@export var damage_text_color: Color = Color(1, 0.25, 0.25, 1)

var target: Node = null
var _last_health_value: int = -1
var _damage_label: Label = null
var _damage_tween: Tween = null


func _ready() -> void:
	_ensure_damage_label()
	_assign_target_from_path()
	call_deferred("_refresh")


func _exit_tree() -> void:
	_disconnect_target_signal()


func set_target(new_target: Node) -> void:
	if target == new_target:
		return

	_disconnect_target_signal()
	target = new_target
	_last_health_value = -1
	_connect_target_signal()
	_refresh()


func _assign_target_from_path() -> void:
	if target_path == NodePath(""):
		return

	var found_target := get_node_or_null(target_path)
	if found_target:
		set_target(found_target)


func _connect_target_signal() -> void:
	if target == null:
		return

	if target.has_signal("health_changed"):
		var callback := Callable(self , "_on_health_changed")
		if not target.is_connected("health_changed", callback):
			target.connect("health_changed", callback)


func _disconnect_target_signal() -> void:
	if target == null:
		return

	if target.has_signal("health_changed"):
		var callback := Callable(self , "_on_health_changed")
		if target.is_connected("health_changed", callback):
			target.disconnect("health_changed", callback)


func _on_health_changed(_new_value: int) -> void:
	_refresh()


func _refresh() -> void:
	if target == null:
		min_value = 0
		max_value = 100
		value = 100
		_last_health_value = -1
		if show_health_text:
			tooltip_text = "No target"
		return

	var current := _get_health_value()
	var max_hp := _get_max_health_value()
	_show_damage_delta_if_needed(current)

	min_value = 0
	max_value = 100
	var hp_percent := (float(current) / float(max(1, max_hp))) * 100.0
	value = clamp(hp_percent, 0.0, 100.0)

	if show_health_text:
		tooltip_text = "%d / %d" % [int(value), int(max_value)]


func _get_health_value() -> int:
	if target == null:
		return 0

	var raw = target.get("current_health")
	if raw == null:
		return _get_max_health_value()
	return int(raw)


func _get_max_health_value() -> int:
	if target == null:
		return 1

	if target.has_method("get_max_health"):
		return int(target.call("get_max_health"))

	var raw = target.get("max_health")
	if raw == null:
		return max(1, _get_health_value())
	return int(raw)


func _ensure_damage_label() -> void:
	if _damage_label:
		return

	_damage_label = Label.new()
	_damage_label.name = "DamageDelta"
	_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_label.position = Vector2(size.x - 56.0, -24.0)
	_damage_label.modulate = damage_text_color
	_damage_label.text = ""
	add_child(_damage_label)


func _show_damage_delta_if_needed(current_health: int) -> void:
	if not show_damage_delta:
		_last_health_value = current_health
		return

	if _last_health_value < 0:
		_last_health_value = current_health
		return

	var subtracted: int = _last_health_value - current_health
	_last_health_value = current_health
	if subtracted <= 0:
		return

	_ensure_damage_label()
	if _damage_label == null:
		return

	_damage_label.text = "-%d" % subtracted
	_damage_label.modulate = damage_text_color
	_damage_label.modulate.a = 1.0
	_damage_label.position = Vector2(size.x - 56.0, -24.0)

	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()

	_damage_tween = create_tween()
	_damage_tween.tween_interval(max(0.0, _scaled_time(damage_text_hold_duration)))
	_damage_tween.parallel().tween_property(_damage_label, "position", Vector2(size.x - 56.0, -34.0), _scaled_time(damage_text_fade_duration))
	_damage_tween.parallel().tween_property(_damage_label, "modulate:a", 0.0, _scaled_time(damage_text_fade_duration))


func _scaled_time(base_duration: float) -> float:
	return base_duration / max(0.01, game_speed)
