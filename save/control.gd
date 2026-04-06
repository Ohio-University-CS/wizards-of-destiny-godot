extends Control
# Called when the node enters the scene tree for the first time.

var player_data


func _ready() -> void:
	pass
	#load_player_data("save_1")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#pass

func write_out_gamestate():
	
	pass


#func load_player_data(save_file_name) -> bool:
	#var file_path = "save/" + save_file_name + ".json"
	#if FileAccess.file_exists(file_path):
		#var save_file = FileAccess.open(file_path, FileAccess.READ)
		#var save_text = save_file.get_as_text()
		#var save_data = JSON.parse_string(save_text)
		#if save_data is Dictionary:
			#player_data = save_data["player"]
		#else:
			#print("Save file corrupted, unable to read")
			#return false
		#return true
	#else:
		#print("Save file \"" + file_path + "\" could not be found")  
		#return false
