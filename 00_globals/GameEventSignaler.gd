extends Node

@warning_ignore("unused_signal")
signal combat_end(player_state : Player)

@warning_ignore("unused_signal")
signal first_combat_begin(player_state : Player)
@warning_ignore("unused_signal")
signal next_combat_begin(player_state : Player)

#signal shop_start()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("ready")
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
