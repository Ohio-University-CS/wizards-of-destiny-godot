# Collection Page

extends Control

@onready var back_button : Button = $Buttons/Exit
@onready var item_list : GridContainer = $ScrollContainer/ItemList

@onready var view_item : Control = $ItemView
@onready var view_item_art : TextureRect = $ItemView/Art
@onready var view_item_name : Label = $ItemView/Tooltip/NameLabel
@onready var view_item_desc : Label = $ItemView/Tooltip/DescriptionLabel
@onready var view_item_rarity : Label = $ItemView/Tooltip/RarityLabel

@export var item_scene : PackedScene

func _ready() -> void:
	view_item.visible = false
	setup_button_hover(back_button)
	back_button.pressed.connect(_on_back_pressed)
	show_items(ItemUnlockManager.all_items, item_scene)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")


# Call this to populate the item view with items
func show_items(items: Array, _item_scene: PackedScene):
	for child in item_list.get_children():
		child.queue_free()
	for item_data in items:
		var item_ui = _item_scene.instantiate()
		item_ui.setup(item_data)
		item_ui.scale *= 1.5
		item_ui.hovered.connect(_show_item)
		item_ui.unhovered.connect(_hide_item)
		item_list.add_child(item_ui)
	# Ensure the grid container grows with its content for scrolling
	item_list.custom_minimum_size = item_list.get_combined_minimum_size()
	visible = true


func _show_item(item_data : ItemData):
	if item_data == null:
		return
		
	view_item_art.texture = item_data.art
	view_item_name.text = item_data.item_name
	view_item_desc.text = item_data.description
	
	if item_data.rarity == ItemData.Rarity.COMMON:
		view_item_rarity.text = "Common"
	elif item_data.rarity == ItemData.Rarity.UNCOMMON:
		view_item_rarity.text = "Uncommon"
	else:
		view_item_rarity.text = "Rare"
	
	view_item.visible = true


func _hide_item():
	view_item.visible = false


#used for buttons
func tween_button_scale(button: Control, target_scale: Vector2):
	var tween = create_tween()
	tween.tween_property(button, "scale", target_scale, 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)


func setup_button_hover(button: BaseButton):
	button.mouse_entered.connect(func():
		tween_button_hover(button, true)
		#start_hover_pulse(button)
	)
	
	button.mouse_exited.connect(func():
		tween_button_hover(button, false)
	)


func tween_button_hover(button: BaseButton, hovering: bool):
	var tween = create_tween()
	
	if hovering:
		tween.tween_property(button, "scale", Vector2(1.6, 1.6), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1.15, 1.15, 1.15), 
			0.15
		)
	else:
		tween.tween_property(button, "scale", Vector2(1.5, 1.5), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		
		tween.parallel().tween_property(
			button, 
			"self_modulate", 
			Color(1, 1, 1), 
			0.15
		)
