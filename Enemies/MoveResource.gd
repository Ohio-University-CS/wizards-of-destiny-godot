# Used to create enemy moves

extends Resource
class_name MoveResource

#-------------
# Variables
#-------------

@export_category("Enemy Move Data")

@export var name : String = "Attack"

@export var effects : Array[Effect] = []

@export var weight : int = 100 # used for enemy AI selection

@export var cooldown : int = 0 # probably use later

@export var element : String = "physical" # optional

@export var intent_icons : Array[Texture2D] = [] # what icons to show for intent
