extends Node2D

@onready var player = $Player
@onready var card = $Card
@onready var enemy = $Enemy

func _ready():
	# Connect the card's signal to the player's function
	card.card_clicked.connect(player.perform_attack)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
