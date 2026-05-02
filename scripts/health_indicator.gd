# Health Indicator
extends Label

var _tween: Tween = null
var hold_time: float = 1.0
var fade_time: float = 0.8
var _last_health: int 
var _active: bool = false

func _ready() -> void:
	# Find the nearest parent that emits `damaged` and/or `health_changed` signals
	var p: Node = get_parent()
	var entity: Node = null
	while p != null:
		if p.has_signal("damaged") or p.has_signal("health_changed"):
			entity = p
			break
		p = p.get_parent()

	if entity != null:
		if entity.has_signal("damaged"):
			if not entity.is_connected("damaged", Callable(self, "_on_damaged")):
				entity.connect("damaged", Callable(self, "_on_damaged"))
		if entity.has_signal("health_changed"):
			if not entity.is_connected("health_changed", Callable(self, "_on_health_changed")):
				entity.connect("health_changed", Callable(self, "_on_health_changed"))

		# Initialize last health value if available
		if entity.get("current_health") != null:
			_last_health = int(entity.get("current_health"))

	# Start invisible
	var m = modulate
	m.a = 0.0
	modulate = m
	text = ""

	# Activate after ready to avoid reacting to startup signals
	call_deferred("_activate")

func _activate() -> void:
	_active = true

func _on_damaged(amount: int) -> void:
	if not _active:
		return

	# Show damage amount briefly and fade out
	if _tween and _tween.is_valid():
		_tween.kill()

	text = "-%d" % int(amount)
	modulate = Color(1, 0.15, 0.15, 1.0)

	_tween = create_tween()
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.play()
	await _tween.finished
	if is_instance_valid(self):
		text = ""

func _on_health_changed(new_value: int) -> void:
	# If not yet active, silently set last health and ignore
	if not _active:
		if _last_health == null:
			_last_health = int(new_value)
		return

	if _last_health == null:
		_last_health = int(new_value)
		return

	var delta := int(new_value) - int(_last_health)
	_last_health = int(new_value)
	if delta > 0:
		if _tween and _tween.is_valid():
			_tween.kill()

		text = "+%d" % delta
		modulate = Color(0.2, 1.0, 0.2, 1.0)

		_tween = create_tween()
		_tween.tween_interval(hold_time)
		_tween.tween_property(self, "modulate:a", 0.0, fade_time)
		_tween.play()
		await _tween.finished
		if is_instance_valid(self):
			text = ""
