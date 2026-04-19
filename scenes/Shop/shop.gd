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
	# Setup items with rarity logic
	for child in items_container.get_children():
		child.queue_free()

	var item_pool = pick_items_for_shop(shop_item_amount)
	for data in item_pool:
		var ui = shop_item_scene.instantiate()
		var price = _get_item_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_item_purchased)
		items_container.add_child(ui)


# --- Rarity-based item selection helpers ---
func get_items_by_rarity():
	var items_by_rarity = {
		"common": [],
		"uncommon": [],
		"rare": []
	}
	for item in ItemUnlockManager.get_unlocked_items():
		if not RunManager.has_item(item.item_name):
			match item.rarity:
				item.Rarity.COMMON:
					items_by_rarity["common"].append(item)
				item.Rarity.UNCOMMON:
					items_by_rarity["uncommon"].append(item)
				item.Rarity.RARE:
					items_by_rarity["rare"].append(item)
	return items_by_rarity

func pick_items_for_shop(amount):
	var items_by_rarity = get_items_by_rarity()
	var weights = get_item_rarity_weights()
	var pool = []
	var rarities = ["common", "uncommon", "rare"]

	while pool.size() < amount:
		# Weighted random rarity selection
		var roll = rng.randf()
		var acc = 0.0
		var chosen_rarity = "common"
		
		for rarity in rarities:
			acc += weights[rarity]
			if roll < acc:
				chosen_rarity = rarity
				break
		
		# Pick a random item from that rarity
		if items_by_rarity[chosen_rarity].size() > 0:
			var idx = rng.randi_range(0, items_by_rarity[chosen_rarity].size() - 1)
			pool.append(items_by_rarity[chosen_rarity][idx])
			items_by_rarity[chosen_rarity].remove_at(idx)
		else:
			# If no items left in this rarity, try another
			rarities.erase(chosen_rarity)
			if rarities.size() == 0:
				break
	return pool



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


func get_item_rarity_weights():
	if RunManager.level_floor == 1 and RunManager.stage < 8:
		return {
			"common": 0.7,
			"uncommon": 0.3,
			"rare": 0.0
		}
	else:
		return {
			"common": 0.55,
			"uncommon": 0.3,
			"rare": 0.15
		}


func _on_card_purchased(_card_data):
	_update_coin_visual()



# Called when an item is purchased from the shop
func _on_item_purchased(item_data):
	# Add the item to the player's inventory
	RunManager.add_item(item_data)
	# Remove the purchased item UI from the shop
	for child in items_container.get_children():
		if child.item_data == item_data:
			child.queue_free()
			break
	_update_coin_visual()


func _update_coin_visual():
	coins.text = str(RunManager.coins)


func _on_next_stage_pressed():
	FlowManager.after_shop()
