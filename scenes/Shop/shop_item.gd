class_name ShopItem
extends Resource

enum Type { CARD, ITEM, SERVICE }

@export var type : Type
@export var cost : int

# Flexible payload
@export var card_data : CardData
@export var item_data : Resource #placeholder
@export var service_id : String # "remove", "heal", etc.


func get_display_name() -> String:
	match type:
		Type.CARD:
			return card_data.card_name
		Type.ITEM:
			return item_data.name if item_data else "Item"
		Type.SERVICE:
			return service_id.capitalize()
	
	return "Unknown"
