# UI for a single item in the collection page
extends Control
class_name CollectionItemUI

signal hovered(item_data)
signal unhovered()

@onready var art_texture : TextureRect = $Art

var item_data : ItemData


func _ready() -> void:
	pass


func setup(data: ItemData):
	item_data = data
	
	await ready
	
	art_texture.texture = item_data.art
	
	# Tooltip/description
	art_texture.mouse_entered.connect(_show_tooltip)
	art_texture.mouse_exited.connect(_hide_tooltip)


func _show_tooltip():
	if item_data == null:
		return
	
	hovered.emit(item_data)


func _hide_tooltip():
	unhovered.emit()
