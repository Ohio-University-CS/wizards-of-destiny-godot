# UI for a single item in the shop
extends Control
class_name ShopItemUI

signal purchased(item_data)

@onready var art_texture : TextureRect = $VBoxContainer/Art
@onready var buy_button : Button = $VBoxContainer/BuyButton

@onready var tooltip : Control = $Tooltip
@onready var tooltip_name : Label = $Tooltip/NameLabel
@onready var tooltip_desc : Label = $Tooltip/DescriptionLabel

var item_data : ItemData
var price : int


func _ready() -> void:
	pass


func setup(data: ItemData, cost: int):
	item_data = data
	price = cost
	
	await ready
	
	art_texture.texture = item_data.art
	buy_button.text = "Buy (" + str(price) + ")"
	buy_button.disabled = RunManager.coins < price
	buy_button.pressed.connect(_on_buy_pressed)
	
	# Tooltip/description
	art_texture.mouse_entered.connect(_show_tooltip)
	art_texture.mouse_exited.connect(_hide_tooltip)
	buy_button.mouse_entered.connect(_show_tooltip)
	buy_button.mouse_exited.connect(_hide_tooltip)

func _show_tooltip():
	if item_data == null:
		return
	
	tooltip.visible = true
	tooltip_name.text = item_data.item_name
	tooltip_desc.text = item_data.description

func _hide_tooltip():
	tooltip.visible = false

func _on_buy_pressed():
	if RunManager.coins < price:
		return
	RunManager.coins -= price
	RunManager.add_item(item_data)
	buy_button.disabled = true
	emit_signal("purchased", item_data)
