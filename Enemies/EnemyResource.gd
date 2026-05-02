# Parent class for creating enemy resources

extends Resource
class_name EnemyResource

enum ElementType {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING
}

@export_category("Enemy Data")

@export var enemy_name: String = "Null"
@export var hp_variation: Array[int]
@export var base_damage: int = 0

@export var moves: Array[MoveResource] = [] # Array of MoveResource

@export var passive_effects: Array[EffectData] = []

@export var element_modifiers: Dictionary = {}
