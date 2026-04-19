# Handles the after-combat shop

extends Control
class_name Shop
 
@onready var next_stage_button : Button = $"Buttons/Next Stage"
@onready var cards_container : GridContainer = $CardsContainer
@onready var items_container : HBoxContainer = $ItemsContainer
@onready var coins : Label = $CoinAmount

@export var player : Player
@export var shop_card_scene : PackedScene
@export var shop_item_scene : PackedScene

# temporary card pool, has all cards
@export var available_cards : Array[CardData]

# temporary item pool
@export var available_items : Array[ItemData]

# number of everything that appears in shop
var shop_card_amount : int = 4
var shop_item_amount : int = 3

# setting rng to run seed
var rng


func _ready() -> void:
	player = RunManager.player
	player.visible = false
	
	rng = RunManager.get_rng()
	
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	_update_coin_visual()
	_generate_shop()


func _generate_shop():
	# Setup cards
	for child in cards_container.get_children():
		child.queue_free()
	
	var card_pool = available_cards.duplicate()
	for i in range(card_pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = card_pool[i]
		card_pool[i] = card_pool[j]
		card_pool[j] = temp
	
	for i in range(shop_card_amount):
		if i >= card_pool.size():
			break
		
		var data = card_pool[i]
		
		var ui = shop_card_scene.instantiate()
		var price = _get_card_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_card_purchased)
		cards_container.add_child(ui)
	
	# ----
	# Setup items
	for child in items_container.get_children():
		child.queue_free()
	
	var item_pool = available_items.duplicate()
	for i in range(item_pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = item_pool[i]
		item_pool[i] = item_pool[j]
		item_pool[j] = temp
	
	for i in range(shop_item_amount):
		if i >= item_pool.size():
			break
		
		var data = item_pool[i]

		var ui = shop_item_scene.instantiate()
		var price = _get_item_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_item_purchased)
		items_container.add_child(ui)



func _get_card_price(card : CardData) -> int:
	match card.rarity:
		card.CardRarity.COMMON:
			return 12
		card.CardRarity.UNCOMMON:
			return 25
		card.CardRarity.RARE:
			return 50
		_:
			return 8


func _get_item_price(item : ItemData) -> int:
	match item.rarity:
		item.Rarity.COMMON:
			return 15
		item.Rarity.UNCOMMON:
			return 30
		item.Rarity.RARE:
			return 60
		_:
			return 10


func _on_card_purchased(_card_data):
	_update_coin_visual()


func _on_item_purchased(_item_data):
	_update_coin_visual()


func _update_coin_visual():
	coins.text = str(RunManager.coins)


func _on_next_stage_pressed():
	FlowManager.after_shop()
