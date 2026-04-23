extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_level_label()
	if RunManager.run_progress_changed.is_connected(_on_run_progress_changed) == false:
		RunManager.run_progress_changed.connect(_on_run_progress_changed)


func _exit_tree() -> void:
	if RunManager.run_progress_changed.is_connected(_on_run_progress_changed):
		RunManager.run_progress_changed.disconnect(_on_run_progress_changed)


func _on_run_progress_changed(_level_name: String, _floor: int, _stage_number: int) -> void:
	_update_level_label()


func _update_level_label() -> void:
	var level_name := RunManager.get_level_name()
	text = "%s - Floor %d" % [level_name, RunManager.level_floor]
