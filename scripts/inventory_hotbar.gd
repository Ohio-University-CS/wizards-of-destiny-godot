extends HBoxContainer

signal item_used(slot_index: int, item: Variant)

@export_range(1, 12, 1) var slot_count: int = 3
@export var slot_bg_normal: Color = Color(0.18, 0.18, 0.2, 0.95)
@export var slot_bg_hover: Color = Color(0.24, 0.24, 0.28, 0.98)
@export var slot_bg_pressed: Color = Color(0.12, 0.12, 0.14, 1.0)
@export var slot_border_color: Color = Color(0.36, 0.36, 0.42, 1.0)
@export var slot_text_color: Color = Color(0.92, 0.92, 0.95, 1.0)

var slots: Array[Variant] = [null, null, null]
var _slot_buttons: Array[Button] = []


func _ready() -> void:
	_ensure_slot_array_size()
	_build_slot_buttons()
	_refresh_slot_labels()


func set_item(slot_index: int, item: Variant) -> void:
	if not _is_valid_slot(slot_index):
		return
	slots[slot_index] = item
	_refresh_slot_labels()


func get_item(slot_index: int) -> Variant:
	if not _is_valid_slot(slot_index):
		return null
	return slots[slot_index]


func use_item(slot_index: int) -> void:
	if not _is_valid_slot(slot_index):
		return

	var item: Variant = slots[slot_index]
	if item == null:
		return

	emit_signal("item_used", slot_index, item)

	# Default behavior for now: consume the item after use if not explicitly non-consumable.
	var is_consumable: bool = true
	if item is Dictionary and item.has("consumable"):
		is_consumable = bool(item["consumable"])

	if is_consumable:
		slots[slot_index] = null

	_refresh_slot_labels()


func _on_slot_pressed(slot_index: int) -> void:
	use_item(slot_index)


func _ensure_slot_array_size() -> void:
	slots.resize(slot_count)


func _build_slot_buttons() -> void:
	for child in get_children():
		child.queue_free()
	_slot_buttons.clear()

	for index in range(slot_count):
		var slot_button := Button.new()
		slot_button.name = "Slot%d" % (index + 1)
		slot_button.custom_minimum_size = Vector2(110, 56)
		slot_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_apply_slot_style(slot_button)
		slot_button.pressed.connect(func() -> void:
			_on_slot_pressed(index)
		)
		add_child(slot_button)
		_slot_buttons.append(slot_button)


func _refresh_slot_labels() -> void:
	for index in range(min(slot_count, _slot_buttons.size())):
		var slot_item: Variant = slots[index]
		var button := _slot_buttons[index]
		if slot_item == null:
			button.text = "Empty"
			continue

		if slot_item is Dictionary and slot_item.has("name"):
			button.text = str(slot_item["name"])
		else:
			button.text = str(slot_item)


func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < slot_count


func _apply_slot_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_stylebox(slot_bg_normal))
	button.add_theme_stylebox_override("hover", _make_stylebox(slot_bg_hover))
	button.add_theme_stylebox_override("pressed", _make_stylebox(slot_bg_pressed))
	button.add_theme_stylebox_override("focus", _make_stylebox(slot_bg_hover))
	button.add_theme_color_override("font_color", slot_text_color)
	button.add_theme_color_override("font_hover_color", slot_text_color)
	button.add_theme_color_override("font_pressed_color", slot_text_color)


func _make_stylebox(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = slot_border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	return style
