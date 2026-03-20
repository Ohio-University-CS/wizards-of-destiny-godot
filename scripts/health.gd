extends Label

@export var target_path: NodePath
@export var show_health_text: bool = true

var target: Node = null
var _label: Label = null

func _ready() -> void:
	_ensure_label()
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
	var found_target := get_node_or_null(target_path)
	if found_target:
		set_target(found_target)

func _connect_target_signal() -> void:
	if target == null:
		return
	if target.has_signal("health_changed"):
		var callback := Callable(self, "_on_health_changed")
		if not target.is_connected("health_changed", callback):
			target.connect("health_changed", callback)

func _disconnect_target_signal() -> void:
	if target == null:
		return
	if target.has_signal("health_changed"):
		var callback := Callable(self, "_on_health_changed")
		if target.is_connected("health_changed", callback):
			target.disconnect("health_changed", callback)

func _on_health_changed(_new_value: int) -> void:
	_refresh()

func _refresh() -> void:
	if target == null:
		if show_health_text and _label:
			_label.text = "No target"
		return

	var current := _get_health_value()
	var max_hp := _get_max_health_value()

	if show_health_text and _label:
		_label.text = "%d / %d" % [int(current), int(max_hp)]

func _get_health_value() -> int:
	if target == null:
		return 0
	var raw = target.get("current_health")
	if raw != null:
		return int(raw)
	if target.has_method("get_current_health"):
		var v = target.call("get_current_health")
		if v != null:
			return int(v)
	return 0

func _get_max_health_value() -> int:
	if target == null:
		return 1
	if target.has_method("get_max_health"):
		var v = target.call("get_max_health")
		if v != null:
			return int(v)
	var raw = target.get("max_health")
	if raw != null:
		return int(raw)
	var curr = target.get("current_health")
	if curr != null:
		return max(1, int(curr))
	return 1

func _ensure_label() -> void:
	_label = $"Label" if has_node("Label") else null
	if _label == null:
		_label = Label.new()
		_label.name = "Label"
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.anchor_left = 0.0
		_label.anchor_top = 0.0
		_label.anchor_right = 1.0
		_label.anchor_bottom = 1.0
		add_child(_label)
