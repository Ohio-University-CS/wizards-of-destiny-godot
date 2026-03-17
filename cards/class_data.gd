extends Resource
class_name ClassData

@export var deck_name : String

# Base Stats
@export var max_health: int = 50
@export var damage: int = 5
@export var elemental_power: float = 0.5
@export var crit_chance: float = 0.1
@export var crit_damage: int = 5
@export var dodge: float = 0.05

@export var max_energy: int = 3

# Starting Deck (10 cards)
@export var starting_deck: Array[CardData]
