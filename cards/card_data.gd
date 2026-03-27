# Parent class, handles card information

extends Resource
class_name CardData

enum CardType { ATTACK, SKILL, POWER }
enum CardFlag { NONE, RITUAL, PASSIVE }
enum CardRarity { COMMON, UNCOMMON, RARE }

@export var card_name : String
@export var description : String
@export var energy_cost : int = 1
@export var rarity : CardRarity = CardRarity.COMMON

@export var card_type : CardType
@export var card_flag : CardFlag = CardFlag.NONE

@export var artwork : Texture2D
@export var frame_art : Texture2D

@export var effects : Array[Effect]

var temporary : bool = false
