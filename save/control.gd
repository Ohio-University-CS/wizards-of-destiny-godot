extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func load_settings() -> bool:
	var settings_file = file("save/settings.wod")
	if settings_file.file_exists():
		
