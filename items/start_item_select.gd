extends Control

@onready var item1_button : Button = $Buttons/Item1
@onready var item2_button : Button = $Buttons/Item2
@onready var item3_button : Button = $Buttons/Item3

@onready var tooltip : Control = $Tooltip
@onready var tooltip_name : Label = $Tooltip/NameLabel
@onready var tooltip_desc : Label = $Tooltip/DescriptionLabel

@export var item_options : Array[ItemData]


var item1 : ItemData
var item2 : ItemData
var item3 : ItemData

func _ready():
	item1_button.pressed.connect(_on_item1_picked)
	item2_button.pressed.connect(_on_item2_picked)
	item3_button.pressed.connect(_on_item3_picked)
	
	item1_button.mouse_entered.connect(func(): _show_tooltip(item1))
	item2_button.mouse_entered.connect(func(): _show_tooltip(item2))
	item3_button.mouse_entered.connect(func(): _show_tooltip(item3))

	item1_button.mouse_exited.connect(_hide_tooltip)
	item2_button.mouse_exited.connect(_hide_tooltip)
	item3_button.mouse_exited.connect(_hide_tooltip)
	
	_generate_choice()


func _generate_choice():
	var pool = item_options.duplicate()
	pool.shuffle()
	
	if pool.size() < 3:
		return
	
	item1 = pool[0]
	item2 = pool[1]
	item3 = pool[2]
	
	item1_button.icon = item1.art
	item2_button.icon = item2.art
	item3_button.icon = item3.art


func _on_item1_picked():
	print("Item chosen: ", item1.item_name)
	RunManager.add_item(item1)
	FlowManager.go_to_combat()


func _on_item2_picked():
	print("Item chosen: ", item2.item_name)
	RunManager.add_item(item2)
	FlowManager.go_to_combat()


func _on_item3_picked():
	print("Item chosen: ", item3.item_name)
	RunManager.add_item(item3)
	FlowManager.go_to_combat()


# ---------------
# Tooltip
# ---------------

func _show_tooltip(item : ItemData):
	if item == null:
		return
	
	tooltip.visible = true
	tooltip_name.text = item.item_name
	tooltip_desc.text = item.description


func _hide_tooltip():
	tooltip.visible = false
