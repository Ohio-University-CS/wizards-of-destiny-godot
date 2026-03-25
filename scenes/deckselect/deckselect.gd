extends Control

@onready var forward_button : Button = $"Buttuons/forward"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	forward_button.pressed.connect(_on_forward_button_pressed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_forward_button_pressed():
	get_tree().change_scene_to_file("")
