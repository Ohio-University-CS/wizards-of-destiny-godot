# Info Page

extends Control

@onready var back_button : Button = $Buttons/Exit
@onready var info : Control = $Info
@onready var info_art : TextureRect = $Info/TextureRect
@onready var info_name : Label = $Info/Panel/Name
@onready var info_desc : Label = $Info/Panel/Description
@onready var effect_list : GridContainer = $EffectList

@onready var block : TextureRect = $EffectList/Block
@onready var broken : TextureRect = $EffectList/Broken
@onready var burn : TextureRect = $EffectList/Burn
@onready var corroded : TextureRect = $EffectList/Corroded
@onready var drained : TextureRect = $EffectList/Drained
@onready var empowered : TextureRect = $EffectList/Empowered
@onready var evasive : TextureRect = $EffectList/Evasive
@onready var freeze : TextureRect = $EffectList/Freeze
@onready var rage : TextureRect = $EffectList/Rage
@onready var regeneration : TextureRect = $EffectList/Regeneration
@onready var sealed : TextureRect = $EffectList/Sealed
@onready var shock : TextureRect = $EffectList/Shock
@onready var stun : TextureRect = $EffectList/Stun

func _ready() -> void:
	info.visible = false
	setup_button_hover(back_button)
	back_button.pressed.connect(_on_back_pressed)
	
	for child in effect_list.get_children():
		child.mouse_entered.connect(func(): _show_info(child))
		child.mouse_exited.connect(_hide_info)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")


func _show_info(_effect : TextureRect):
	info.visible = true
	info_art.texture = _effect.texture
	
	if _effect == block:
		info_name.text = "Block"
		info_desc.text = "Prevents incoming damage, removed at start of turn"
	elif _effect == broken:
		info_name.text = "Broken"
		info_desc.text = "(Player only) Strike doesn't trigger [max: 1]"
	elif _effect == burn:
		info_name.text = "Burn"
		info_desc.text = "Deals Fire damage per stack at start of turn, removes one stack"
	elif _effect == corroded:
		info_name.text = "Corroded"
		info_desc.text = "+2 damage taken per stack, remove one stack"
	elif _effect == drained:
		info_name.text = "Drained"
		info_desc.text = "(Player only) Draw one less card per stack [max: 3]"
	elif _effect == empowered:
		info_name.text = "Empowered"
		info_desc.text = "Deal +3 damage per stack, remove one stack at end of turn"
	elif _effect == evasive:
		info_name.text = "Evasive"
		info_desc.text = "(Enemy only) Dodge next attack, remove a stack. Remove all stacks at start of turn [max: 2]"
	elif _effect == freeze:
		info_name.text = "Freeze"
		info_desc.text = "-2 damage per stack, remove all stacks"
	elif _effect == rage:
		info_name.text = "Rage"
		info_desc.text = "(Enemy only) Deal +1 damage per stack [permanent]"
	elif _effect == regeneration:
		info_name.text = "Regeneration"
		info_desc.text = "Heal health equal to number of stacks at start of turn, remove all stacks"
	elif _effect == sealed:
		info_name.text = "Sealed"
		info_desc.text = "(Player only) Only Strike deals damage"
	elif _effect == shock:
		info_name.text = "Shock"
		info_desc.text = "Take Lightning damage equal to number of stacks when attacking, remove one stack"
	elif _effect == stun:
		info_name.text = "Stun"
		info_desc.text = "Skip turn"


func _hide_info():
	info.visible = false


# ----------------
# Used for buttons
# ----------------

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
