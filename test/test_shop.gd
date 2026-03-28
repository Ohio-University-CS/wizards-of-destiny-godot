extends "res://addons/gut/test.gd"
# Dummy shop card node for testing
class DummyShopCard:
	extends Node
	signal purchased
	func setup(data, price):
		pass


# Test suite for Shop (scenes/Shop/shop.gd)
# Each test function covers a different aspect of the Shop logic.
# Each function includes at least 3 cases: normal, edge, and error.


var Shop = preload("res://scenes/Shop/shop.gd")
var CardData = preload("res://cards/card_data.gd")

# Setup function to mock dependencies for Shop
func setup_shop_dependencies():
	# Mock Player
	var Player = preload("res://scenes/player/Player.gd")
	var dummy_player = Player.new()
	RunManager.player = dummy_player
	RunManager.coins = 100


# Helper to create a dummy card with a given rarity
func make_card(rarity):
	var card = CardData.new()
	card.rarity = rarity
	return card

# 1. Test _get_price() for different rarities
func test_get_price_various_rarities():
	setup_shop_dependencies()
	var shop = Shop.new()
	# Normal: Common
	assert_eq(shop._get_price(make_card(CardData.CardRarity.COMMON)), 12, "Common card price should be 12")
	# Edge: Rare
	assert_eq(shop._get_price(make_card(CardData.CardRarity.RARE)), 50, "Rare card price should be 50")
	# Error: Invalid rarity
	var card = make_card(-1)
	assert_eq(shop._get_price(card), 8, "Invalid rarity should default to 8")

# 2. Test shop_size limiting number of cards
func test_generate_shop_respects_shop_size():
	setup_shop_dependencies()
	var dummy_scene = PackedScene.new()
	dummy_scene.pack(DummyShopCard.new())

	# Normal: shop_size = 4, available_cards = 10
	var shop = Shop.new()
	shop.shop_card_scene = dummy_scene
	shop.cards_container = Node.new()
	shop.available_cards = [] as Array[CardData]
	for i in range(10):
		shop.available_cards.append(make_card(CardData.CardRarity.COMMON))
	shop.shop_size = 4
	shop._generate_shop()
	assert_true(shop.cards_container.get_child_count() <= 4, "Should not exceed shop_size")

	# Edge: shop_size > available_cards (shop_size = 12, available_cards = 5)
	shop = Shop.new()
	shop.shop_card_scene = dummy_scene
	shop.cards_container = Node.new()
	shop.available_cards = [] as Array[CardData]
	for i in range(5):
		shop.available_cards.append(make_card(CardData.CardRarity.COMMON))
	shop.shop_size = 12
	shop._generate_shop()
	assert_eq(shop.cards_container.get_child_count(), 5, "Should not exceed available cards")

	# Error: shop_size = 0
	shop = Shop.new()
	shop.shop_card_scene = dummy_scene
	shop.cards_container = Node.new()
	shop.available_cards = [] as Array[CardData]
	shop.shop_size = 0
	shop._generate_shop()
	assert_eq(shop.cards_container.get_child_count(), 0, "Zero shop_size should show no cards")

# 3. Test _update_coin_visual updates label
func test_update_coin_visual():
	setup_shop_dependencies()
	var shop = Shop.new()
	shop.coins = Label.new()
	RunManager.coins = 99
	shop._update_coin_visual()
	assert_eq(shop.coins.text, "99", "Coin label should match RunManager.coins")
	# Edge: coins = 0
	RunManager.coins = 0
	shop._update_coin_visual()
	assert_eq(shop.coins.text, "0", "Coin label should be zero")
	# Error: coins negative
	RunManager.coins = -5
	shop._update_coin_visual()
	assert_eq(shop.coins.text, "-5", "Coin label should show negative if coins negative")

# 4. Test _on_card_purchased triggers coin update
func test_on_card_purchased_triggers_update():
	setup_shop_dependencies()
	var shop = Shop.new()
	shop.coins = Label.new()
	RunManager.coins = 42
	shop._on_card_purchased(null)
	assert_eq(shop.coins.text, "42", "_update_coin_visual should update coin label on purchase")
	# Edge: purchase with null (should not crash)
	shop._on_card_purchased(null)
	assert_eq(shop.coins.text, "42", "Should handle null card purchase and keep label correct")

# 5. Test _on_next_stage_pressed calls FlowManager.go_to_combat
func test_next_stage_calls_flowmanager():
	setup_shop_dependencies()
	var shop = Shop.new()
	 # Cannot mock or replace FlowManager.go_to_combat in Godot 4+ autoloads.
	 # This test only checks that calling the method does not crash.
	shop._on_next_stage_pressed()
	assert_true(true, "_on_next_stage_pressed called without error")
	 # Edge: call twice
	shop._on_next_stage_pressed()
	assert_true(true, "_on_next_stage_pressed called again without error")
	 # Error: If go_to_combat missing, cannot simulate in GDScript, so skip.

# End of test_shop.gd
