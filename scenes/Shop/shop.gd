# Handles the after-combat shop

extends Control
class_name Shop
 
@onready var next_stage_button : Button = $"Buttons/Next Stage"
@onready var cards_container = $CardsContainer
@onready var coins : Label = $CoinAmount

@export var player : Player
@export var shop_card_scene : PackedScene

# temporary card pool, has all cards
@export var available_cards : Array[CardData]

# numbber of cards that appear in shop
var shop_size := 4 


func _ready() -> void:
	player = RunManager.player
	
	player.visible = false
	
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	_update_coin_visual()
	_generate_shop()


func _generate_shop():
	# Setup cards
	for child in cards_container.get_children():
		child.queue_free()
	
	var pool = available_cards.duplicate()
	pool.shuffle()
	
	for i in range(shop_size):
		if i >= pool.size():
			break
		
		var data = pool[i]
		
		var ui = shop_card_scene.instantiate()
		var price = _get_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_card_purchased)
		cards_container.add_child(ui)


func _get_price(card : CardData) -> int:
	match card.rarity:
		card.CardRarity.COMMON:
			return 12
		card.CardRarity.UNCOMMON:
			return 25
		card.CardRarity.RARE:
			return 50
		_:
			return 8


func _on_card_purchased(_card_data):
	_update_coin_visual()


func _update_coin_visual():
	coins.text = str(RunManager.coins)


func _on_next_stage_pressed():
	GameEventSignaler.next_combat_begin.emit(RunManager.player)
	FlowManager.go_to_combat()
