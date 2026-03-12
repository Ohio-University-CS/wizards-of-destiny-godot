extends Resource
class_name EnemyResource
@export_category("Enemy Data")

@export var enemy_name : String = "Goblin"
@export var base_hp : int = 20
@export var moves : Array[Resource] = [] # Array of MoveResource
@export var resistances : Dictionary = {} # e.g., {"fire": 0.5}
@export var vulnerabilities : Dictionary = {} # e.g., {"ice": 1.5}
