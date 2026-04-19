# Item Unlock Manager
extends Node

# All possible items in the game
var all_items : Array[ItemData] = []

# Set of unlocked item names (or unique IDs)
var unlocked_items : Array[String] = []


func _ready():
	load_items_from_json("res://data/items_pool.json")


func load_items_from_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			for rarity in data.keys():
				for res_path in data[rarity]:
					var item_res = load(res_path)
					if item_res:
						all_items.append(item_res)
						print("ItemManager: Loaded ", item_res.item_name)
		file.close()


# Call to unlock an item by name or id
func unlock_item(item_name : String) -> void:
	unlocked_items.append(item_name)


# Returns array of unlocked items (ItemData resources)
func get_unlocked_items() -> Array:
	var result = []
	for item in all_items:
		if unlocked_items.has(item.item_name):
			result.append(item)
	return result
