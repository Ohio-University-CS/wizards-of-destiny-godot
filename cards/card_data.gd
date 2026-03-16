extends Resource
class_name CardData

enum CardType { ATTACK, SKILL, POWER }
enum CardFlag { NONE, RITUAL, PASSIVE }

@export var card_name : String
@export var description : String
@export var energy_cost : int = 1
@export var rarity : String

@export var card_type : CardType
@export var card_flag : CardFlag = CardFlag.NONE

@export var artwork : Texture2D

@export var effects : Array[Effect]
#@export var effects : Array[EffectData]
