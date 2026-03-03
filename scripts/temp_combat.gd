@tool
extends Node2D

@onready var player : Player = null
@onready var deck : CombatDeck = $CombatDeck

@export var card_scene : PackedScene
@export var class_data : ClassData

# Editor preview settings
@export var preview_in_editor: bool = true
@export var preview_count: int = 5


func _ready():
	# Locate the player node by common names or by type to avoid null path errors
	if player == null:
		if has_node("Player"):
			player = $Player
		elif has_node("Player2"):
			player = $Player2
		else:
			for child in get_children():
				if child is Player:
					player = child
					break

	if player:
		player.setup_from_class(class_data)
	else:
		push_error("TempCombat: no Player node found; cannot call setup_from_class")

	if deck:
		deck.setup_from_class(class_data)

	draw_hand()

	# In the editor, create preview cards so you can see them in the scene tree/viewport
	if Engine.is_editor_hint() and preview_in_editor:
		_create_editor_previews()


func _enter_tree():
	if Engine.is_editor_hint() and preview_in_editor:
		_create_editor_previews()

func _exit_tree():
	if Engine.is_editor_hint():
		_clear_editor_previews()

func draw_hand():
	for i in range(5):
		var card_instance = deck.draw_card()
		if card_instance:
			spawn_card(card_instance)

func spawn_card(instance : CardInstance):
	var card = card_scene.instantiate()
	add_child(card)

	card.setup(instance)

	card.position = Vector2(200 + deck.hand.size() * 180, 500)

	card.card_clicked.connect(func(): play_card(card))


func play_card(card_scene):
	var instance = card_scene.card_instance

	var dummy_enemy = player  # temporary target for testing

	if instance.play(dummy_enemy, player):
		if instance.exhausted:
			deck.exhaust_card(instance)
		else:
			deck.discard_card(instance)

		card_scene.queue_free()


func _create_editor_previews():
	_clear_editor_previews()
	if not card_scene:
		return

	for i in range(preview_count):
		var c = card_scene.instantiate()
		c.name = "preview_card_%d" % i
		add_child(c)
		# mark as editor-only so it doesn't persist or affect runtime
		if c.has_method("set_editor_only"):
			c.set_editor_only(true)
		# Position them for visibility
		c.position = Vector2(200 + i * 180, 500)


func _clear_editor_previews():
	var to_remove := []
	for child in get_children():
		if typeof(child.name) == TYPE_STRING and child.name.begins_with("preview_card_"):
			to_remove.append(child)
	for c in to_remove:
		if is_instance_valid(c):
			c.queue_free()
