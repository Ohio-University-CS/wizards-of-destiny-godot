# health bar
extends ProgressBar

var target: Node = null


func _ready() -> void:
	pass


func set_target(new_target: Node) -> void:
	print("HealthBar received target:", new_target)
	if target == new_target:
		return
	
	_disconnect_target_signal()
	target = new_target
	_connect_target_signal()
	_refresh() 


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
		value = 0
		max_value = 1
		return
	
	var current : int = target.current_health
	var max_hp : int = target.get_max_health()

	max_value = max(1, int(max_hp))
	value = clamp(int(current), 0, int(max_value))

