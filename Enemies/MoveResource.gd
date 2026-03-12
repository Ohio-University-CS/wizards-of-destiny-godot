extends Resource
class_name MoveResource
@export_category("Enemy Move Data")

@export var name : String = "Attack"
@export var base_damage : int = 0
@export var status_effects : Dictionary = {} # e.g., {"corroded": 2, "evasive": 1}
@export var weight : int = 100 # used for enemy AI selection
@export var element : String = "physical" # optional
