extends Control
class_name ShopItemUi

@onready var name_label : Label = $Panel/VBoxContainer/NameLabel
@onready var cost_label : Label = $Panel/VBoxContainer/CostLabel
@onready var buy_button : Button = $Panel/VBoxContainer/BuyButton

signal purchased(shop_item)

var shop_item : ShopItem
var current_coins: int #reference to player coins

@export var card_scene : PackedScene


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)


func setup(item : ShopItem, player_coins : int):
	shop_item = item
	current_coins = player_coins
	
	name_label.text = item.get_display_name()
	cost_label.text = str(item.cost)
	
	#show card visually
	if item.type == ShopItem.Type.CARD and card_scene:
		name_label.visible = false
		var card_ui = card_scene.instantiate()
		
		var instance = CardInstance.new(item.card_data)
		card_ui.setup(instance)
		
		#disable interaction
		card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		$Panel/VBoxContainer/CardHolder.add_child(card_ui)
	
	update_affordability()


func update_affordability():
	buy_button.disabled = current_coins < shop_item.cost


func _on_buy_button_pressed():
	purchased.emit(shop_item)
