# Handles the after-combat shop

extends Control
class_name Shop
 
@onready var next_stage_button : Button = $"Buttons/Next Stage"
@onready var cards_container : GridContainer = $CardsContainer
@onready var items_container : HBoxContainer = $ItemsContainer
@onready var buffs_container : HBoxContainer = $BuffsContainer
@onready var coins : Label = $CoinAmount
@onready var deck_view_button : Button = $"Buttons/View Deck"
@onready var deck_view_scene : DeckView = $DeckView
@onready var remove_card_scene : RemoveCard = $RemoveCard

@export var player : Player
@export var shop_card_scene : PackedScene
@export var shop_item_scene : PackedScene
@export var shop_buff_scene : PackedScene
@export var card_scene : PackedScene

# temporary card pool, has all cards
@export var available_cards : Array[CardData]

# Buff pool
@export var shop_scrolls : Array[BuffData]
@export var shop_potions : Array[BuffData]

# number of everything that appears in shop
var shop_card_amount : int = 4
var shop_item_amount : int = 3
var shop_scroll_amount : int = 2
var shop_potion_amount : int = 1

# setting rng to run seed
var rng


func _ready() -> void:
	player = RunManager.player
	#player.visible = false
	
	rng = RunManager.get_rng()
	
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	deck_view_button.pressed.connect(_on_deck_view_pressed)
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
	
	# ----
	
	# Setup buffs
	# Scrolls
	for child in buffs_container.get_children():
		child.queue_free()
	
	var scroll_pool = shop_scrolls.duplicate()
	for i in range(scroll_pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = scroll_pool[i]
		scroll_pool[i] = scroll_pool[j]
		scroll_pool[j] = temp
	
	for i in range(shop_scroll_amount):
		if i >= scroll_pool.size():
			break
		
		var data = scroll_pool[i]
		
		var ui = shop_buff_scene.instantiate()
		var price = _get_buff_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_buff_purchased)
		buffs_container.add_child(ui)
	
	# Potions
	var potion_pool = shop_potions.duplicate()
	for i in range(potion_pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = potion_pool[i]
		potion_pool[i] = potion_pool[j]
		potion_pool[j] = temp
	
	for i in range(shop_potion_amount):
		if i >= potion_pool.size():
			break
		
		var data = potion_pool[i]
		
		# Prevent purple potion if less than 6 cards
		if data.potion_effect[0].get_color() == "PURPLE":
			if RunManager.player.deck_list.size() < 6:
				data = potion_pool[i+1]
		
		var ui = shop_buff_scene.instantiate()
		var price = _get_buff_price(data)
		
		# Comedy Mask
		if RunManager.has_item("Comedy Mask"):
			price *= 0.75
		
		ui.setup(data, price)
		ui.purchased.connect(_on_buff_purchased)
		buffs_container.add_child(ui)


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


func _get_buff_price(buff : BuffData) -> int:
	match buff.price:
		buff.Price.LOW:
			return 20
		buff.Price.MEDIUM:
			return 40
		buff.Price.HIGH:
			return 60
		buff.Price.VERY_HIGH:
			return 70
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


func _on_buff_purchased(buff_data : BuffData):
	# SCROLLS
	if not buff_data.scroll_effect.size() == 0:
		for e in buff_data.scroll_effect:
			e.apply_scroll()
	
	# POTIONS
	if not buff_data.potion_effect.size() == 0:
		for p in buff_data.potion_effect:
			p.apply_potion()
			if p.get_color() == "PURPLE":
				remove_card_scene.show_deck(player.deck_list, card_scene)
	
	# Remove the purchased buff UI from the shop
	for child in buffs_container.get_children():
		if child.buff_data == buff_data:
			child.queue_free()
			break
	_update_coin_visual()


# Called when an item is purchased from the shop
func _on_item_purchased(item_data : ItemData):
	# Add the item to the player's inventory
	RunManager.add_item(item_data)
	# Remove the purchased item UI from the shop
	for child in items_container.get_children():
		if child.item_data == item_data:
			child.queue_free()
			break
	if item_data.item_name == "Comedy Mask":
		_comedy_mask_update()
	_update_coin_visual()


func _update_coin_visual():
	coins.text = str(RunManager.coins)
	update_buttons()


func _on_next_stage_pressed():
	FlowManager.after_shop()


func _on_deck_view_pressed():
	# Show the player's deck in the deck view
	deck_view_scene.show_deck(player.deck_list, shop_card_scene)


func update_buttons():
	var coin_amt = RunManager.coins
	for child in cards_container.get_children():
		if child.price > coin_amt:
			child.buy_button.disabled = true
		else:
			child.buy_button.disabled = false
	for child in items_container.get_children():
		if child.price > coin_amt:
			child.buy_button.disabled = true
		else:
			child.buy_button.disabled = false
	for child in buffs_container.get_children():
		if child.price > coin_amt:
			child.buy_button.disabled = true
		else:
			child.buy_button.disabled = false


func _comedy_mask_update():
	for child in cards_container.get_children():
		child.price *= 0.75
		child.buy_button.text = "Buy (" + str(child.price) + ")"
	for child in items_container.get_children():
		child.price *= 0.75
		child.buy_button.text = "Buy (" + str(child.price) + ")"
	for child in buffs_container.get_children():
		child.price *= 0.75
		child.buy_button.text = "Buy (" + str(child.price) + ")"
