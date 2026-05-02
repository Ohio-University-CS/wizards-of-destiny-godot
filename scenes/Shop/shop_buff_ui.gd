# UI for a single buff in the shop
extends Control
class_name ShopBuffUI

signal purchased(buff_data)

@onready var art_texture : TextureRect = $VBoxContainer/Art
@onready var buy_button : Button = $VBoxContainer/BuyButton

@onready var tooltip : Control = $Tooltip
@onready var tooltip_name : Label = $Tooltip/NameLabel
@onready var tooltip_desc : Label = $Tooltip/DescriptionLabel

var buff_data : BuffData
var price : int


func _ready() -> void:
	pass


func setup(data: BuffData, cost: int):
	buff_data = data
	price = cost
	
	await ready
	
	art_texture.texture = buff_data.art
	buy_button.text = "Buy (" + str(price) + ")"
	buy_button.disabled = RunManager.coins < price
	buy_button.pressed.connect(_on_buy_pressed)
	
	# Tooltip/description
	art_texture.mouse_entered.connect(_show_tooltip)
	art_texture.mouse_exited.connect(_hide_tooltip)
	buy_button.mouse_entered.connect(_show_tooltip)
	buy_button.mouse_exited.connect(_hide_tooltip)

func _show_tooltip():
	if buff_data == null:
		return
	
	tooltip.visible = true
	tooltip_name.text = buff_data.buff_name
	tooltip_desc.text = buff_data.description

func _hide_tooltip():
	tooltip.visible = false

func _on_buy_pressed():
	if RunManager.coins < price:
		return
	RunManager.coins -= price
	buy_button.disabled = true
	emit_signal("purchased", buff_data)
