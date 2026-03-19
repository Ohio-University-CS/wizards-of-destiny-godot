extends Control
class_name Shop
 
@onready var next_stage_button : Button = $"Buttons/Next Stage"

@export var shop_item_scene : PackedScene
@export var player : Player
@export var card_pool : Array[CardData]

var shop_items : Array = []


func _ready() -> void:
	next_stage_button.pressed.connect(_on_next_stage_pressed)
	
	generate_test_shop()
	populate_shop()
	update_coins_display()


func _on_next_stage_pressed():
	pass


func generate_test_shop():
	shop_items.clear()
	
	var available_cards = card_pool.duplicate()
	available_cards.shuffle()
	
	#Example: 3 cards
	for i in range(min(3, available_cards.size())):
		var item = ShopItem.new()
		item.type = ShopItem.Type.CARD
		item.cost = 5 + i
		
		item.card_data = available_cards[i]
		
		shop_items.append(item)


#temporary
func get_random_card() -> CardData:
	if card_pool.is_empty():
		push_error("Card pool is empty")
		return null
	
	return card_pool.pick_random()


#func get_random_card_by_rarity()


func populate_shop():
	for item in shop_items:
		var ui = shop_item_scene.instantiate()
		
		$CardsPanel/CardContainer.add_child(ui)
		
		ui.call_deferred("setup", item, player.coins)
		ui.purchased.connect(_on_item_purchased)


func _on_item_purchased(item : ShopItem):
	if player.coins < item.cost:
		return
	
	player.coins -= item.cost
	update_coins_display()
	
	match item.type:
		ShopItem.Type.CARD:
			add_card_to_deck(item.card_data)
		
		ShopItem.Type.ITEM:
			print("Item Bought (not implemented)")
		
		ShopItem.Type.SERVICE:
			handle_service(item)
	
	refresh_all_ui()


func add_card_to_deck(card_data : CardData):
	player.deck_list.append(card_data)
	print("Added ", card_data.card_name, " to deck")


func refresh_all_ui():
	for child in $CardsPanel/CardContainer.get_children():
		child.current_coins = player.coins
		child.update_affordability()


func update_coins_display():
	$Coins.text = "Coins: " + str(player.coins)


func handle_service(item):
	print("Service not implemented")
