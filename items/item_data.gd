class_name ItemData extends Resource

enum Rarity { COMMON, UNCOMMON, RARE }

@export var item_name : String
@export var description : String
@export var rarity : Rarity = Rarity.COMMON
@export var art : Texture2D
