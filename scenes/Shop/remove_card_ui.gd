# Visuals for cards in the remove menu

extends Control
class_name RemoveCardUI

signal card_selected(card_index)

@export var card_scene : PackedScene

@onready var container : VBoxContainer = $VBoxContainer
@onready var card_holder = $VBoxContainer/CardHolder
@onready var select_button : Button = $VBoxContainer/Select

var card_node : Card
var card_data : CardData
var card_index : int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(200, 330)



# Accepts CardData and index in deck
func setup(data: CardData, index: int):
	card_data = data
	card_index = index
	
	await ready

	if card_scene == null:
		push_error("card scene not assigned in ShopCardUI")
		return
	
	card_node = card_scene.instantiate()
	card_holder.add_child(card_node)
	
	# Setup visual card
	var instance = CardInstance.new(card_data)
	card_node.is_static_display = true
	card_node.setup(instance)
	
	select_button.text = "Select"
	select_button.pressed.connect(_on_select_pressed)


func _on_select_pressed():
	card_selected.emit(card_index)
