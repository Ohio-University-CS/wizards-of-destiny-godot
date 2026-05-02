# Pause Settings Menu - Sound
extends Control

@onready var soundsettings = $"soundsettingoptions"
@onready var main_slider = $"soundsettingoptions/mvs"
@onready var music_slider = $"soundsettingoptions/musicvs"
@onready var sfx_slider = $"soundsettingoptions/sfvs"

func _ready() -> void:
	
	#sound
	main_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))


func _on_mvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)


func _on_musicvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value)


func _on_sfvs_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)
