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
	_refresh() # ✅ immediate update


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



## health_bar
#extends ProgressBar
#
#@export var target_path: NodePath
#var target: Node = null
#
#func _ready() -> void:
	#_assign_target_from_path()
	#call_deferred("_refresh")
#
#func _assign_target_from_path() -> void:
	## If a target path is provided, use it. Otherwise attempt to find an
	## Enemy/Player instance by walking up the parent chain (useful when the
	## progress bar is a child of the combatant node in its scene).
	#if target_path != NodePath(""):
		#var found_target := get_node_or_null(target_path)
		#if found_target:
			#set_target(found_target)
			#return
#
	#var p = get_parent()
	#while p != null:
		#if p is Enemy or p is Player:
			#set_target(p)
			#return
		#p = p.get_parent()
#
	## If still not found, try a scene-wide search for a Player or Enemy instance
	#var root = get_tree().current_scene
	#if root != null:
		## prefer Player over Enemy when both are present
		#for child in root.get_children():
			#if child is Player:
				#set_target(child)
				#return
		## fallback to scanning recursively
		#var found := root.find_child("Player", true, false)
		#if found != null:
			#set_target(found)
			#return
		#found = root.find_child("Enemy", true, false)
		#if found != null:
			#set_target(found)
			#return
#
#func set_target(new_target: Node) -> void:
	#if target == new_target:
		#return
	#_disconnect_target_signal()
	#target = new_target
	#_connect_target_signal()
	#_refresh()
#
#func _connect_target_signal() -> void:
	#if target == null:
		#return
	#if target.has_signal("health_changed"):
		#var callback := Callable(self, "_on_health_changed")
		#if not target.is_connected("health_changed", callback):
			#target.connect("health_changed", callback)
#
#func _disconnect_target_signal() -> void:
	#if target == null:
		#return
	#if target.has_signal("health_changed"):
		#var callback := Callable(self, "_on_health_changed")
		#if target.is_connected("health_changed", callback):
			#target.disconnect("health_changed", callback)
#
#func _on_health_changed(_new_value: int) -> void:
	#_refresh()
#
#func _refresh() -> void:
	#if target == null:
		#value = 0
		#max_value = 1
		#return
#
	#var current := _get_health_value()
	#var max_hp := _get_max_health_value()
	#max_value = max(1, int(max_hp))
	#value = clamp(int(current), 0, int(max_value))
#
#func _get_health_value() -> int:
	#if target == null:
		#return 0
	#var raw = target.get("current_health")
	#if raw != null:
		#return int(raw)
	#if target.has_method("get_current_health"):
		#var v = target.call("get_current_health")
		#if v != null:
			#return int(v)
	#return 0
#
#func _get_max_health_value() -> int:
	#if target == null:
		#return 1
	#if target.has_method("get_max_health"):
		#var v = target.call("get_max_health")
		#if v != null:
			#return int(v)
	#var raw = target.get("max_health")
	#if raw != null:
		#return int(raw)
	#var curr = target.get("current_health")
	#if curr != null:
		#return max(1, int(curr))
	#return 1
