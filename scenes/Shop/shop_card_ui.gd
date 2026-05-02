# Visuals for cards in the shop
# note: scaling is slightly weird

extends Control
class_name ShopCardUI

signal purchased(card_data)

@export var card_scene : PackedScene

@onready var container : VBoxContainer = $VBoxContainer
@onready var card_holder = $VBoxContainer/CardHolder
@onready var buy_button : Button = $VBoxContainer/BuyButton

var card_node : Card
var card_data : CardData
var price : int


func _ready() -> void:
	custom_minimum_size = Vector2(200, 330)
	#card_holder.custom_minimum_size = Vector2(300, 450)


func setup(data: CardData, cost: int):
	card_data = data
	price = cost
	
	await ready
	
	if card_scene == null:
		push_error("card scene not assigned in ShopCardUI")
		return
	
	card_node = card_scene.instantiate()
	card_holder.add_child(card_node)
	
	#card_node.pivot_offset = card_node.size / 2
	#
	#card_node.scale = Vector2(1.2, 1.2)
	#card_holder.custom_minimum_size = Vector2(240, 360)
	
	# Setup visual card
	var instance = CardInstance.new(card_data)
	
	card_node.is_static_display = true
	card_node.setup(instance)

	buy_button.text = "Buy (" + str(price) + ")"
	buy_button.disabled = RunManager.coins < price
	buy_button.pressed.connect(_on_buy_pressed)


func _on_buy_pressed():
	if RunManager.coins < price:
		return

	RunManager.coins -= price
	RunManager.player.deck_list.append(card_data)

	purchased.emit(card_data)
	queue_free()
