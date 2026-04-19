class_name BuffData extends Resource

enum Price { LOW, MEDIUM, HIGH, VERY_HIGH }

@export var buff_name : String
@export var description : String
@export var price : Price = Price.LOW
@export var art : Texture2D
@export var scroll_effect : Array[ScrollEffect]
@export var potion_effect : Array[PotionEffect]
