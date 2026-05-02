extends Control
class_name DeckView

@onready var back_button : Button = $Buttons/Exit
@onready var card_list : GridContainer = $ScrollContainer/CardList


func _ready() -> void:
	setup_button_hover(back_button)
	back_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed():
	visible = false


# Call this to populate the deck view with cards
func show_deck(cards: Array, card_scene: PackedScene):
	for child in card_list.get_children():
		child.queue_free()
	for card_data in cards:
		var card_ui = card_scene.instantiate()
		card_ui.setup(card_data, 0) # Pass CardData and price (0 for deck view)
		if card_ui.has_node("VBoxContainer/BuyButton"):
			card_ui.get_node("VBoxContainer/BuyButton").visible = false
		card_ui.scale *= 1.5
		card_list.add_child(card_ui)
	# Ensure the grid container grows with its content for scrolling
	card_list.custom_minimum_size = card_list.get_combined_minimum_size()
	visible = true


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
		tween.tween_property(button, "scale", Vector2(1.56, 1.56), 0.15)\
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
