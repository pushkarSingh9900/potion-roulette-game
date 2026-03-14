extends Control
class_name CardUI

const ART_ASSETS := preload("res://scripts/art_assets.gd")

signal card_selected(card_ui: CardUI)
signal card_removed(card_ui: CardUI)

var card_data: CardData
var card_key := ""
var card_index := -1
var is_clickable := false
var is_selected := false
var is_face_down := false
var is_hovered := false
var card_count := 0
var selected_count := 0
var hover_tween: Tween
var motion_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = custom_minimum_size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_set_children_mouse_filter(self)


func setup(data: CardData):
	card_data = data
	_refresh_visuals()


func set_card_index(value: int) -> void:
	card_index = value


func set_card_key(value: String) -> void:
	card_key = value


func set_count(value: int) -> void:
	card_count = value
	_refresh_visuals()


func set_clickable(value: bool) -> void:
	is_clickable = value
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
	tooltip_text = "Left click adds one. Right click removes one." if value else ""
	if not is_clickable:
		is_hovered = false
		_animate_hover(false)
	_refresh_visuals()


func set_selected(value: bool) -> void:
	is_selected = value
	_refresh_visuals()


func set_selected_count(value: int) -> void:
	selected_count = value
	_refresh_visuals()


func set_face_down(value: bool) -> void:
	is_face_down = value
	_refresh_visuals()


func _refresh_visuals() -> void:
	var background = $Background
	var border = $Border
	var icon = $Icon
	var selected_badge = $SelectedBadge
	var count_label = $CountLabel
	var count_badge = $CountBadge
	var selected_label = $SelectedLabel

	if is_face_down or card_data == null:
		background.color = Color(0, 0, 0, 0)
		count_label.text = "?"
		selected_label.text = ""
		count_label.visible = true
		icon.texture = null
		icon.visible = false
	else:
		background.color = Color(0, 0, 0, 0)
		icon.texture = ART_ASSETS.get_card_texture(card_data.type)
		icon.visible = icon.texture != null
		count_label.text = "x%d" % card_count if card_count > 0 else ""
		selected_label.text = "+%d" % selected_count if selected_count > 0 else ""
		count_label.visible = count_label.text != ""

	selected_badge.visible = selected_label.text != ""
	count_badge.visible = count_label.visible

	if is_selected:
		border.border_color = Color(0.97, 0.87, 0.49, 1)
		border.border_width = 4.0
	elif is_hovered and is_clickable:
		border.border_color = Color(0.82, 0.88, 1.0, 0.95)
		border.border_width = 3.0
	else:
		border.border_color = Color(0, 0, 0, 0)
		border.border_width = 0.0

	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	count_label.add_theme_constant_override("outline_size", 3)
	selected_label.add_theme_font_size_override("font_size", 16)
	selected_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45, 1))
	selected_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	selected_label.add_theme_constant_override("outline_size", 3)

	background.modulate = Color(1, 1, 1, 1)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_hovered and is_clickable else Color(0.94, 0.94, 0.94, 1.0)


func _gui_input(event: InputEvent) -> void:
	if not is_clickable:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_selected.emit(self)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			card_removed.emit(self)
			accept_event()


func _on_mouse_entered() -> void:
	if not is_clickable or is_face_down:
		return
	is_hovered = true
	_animate_hover(true)
	_refresh_visuals()


func _on_mouse_exited() -> void:
	if not is_hovered:
		return
	is_hovered = false
	_animate_hover(false)
	_refresh_visuals()


func _animate_hover(active: bool) -> void:
	if hover_tween != null:
		hover_tween.kill()
	var target_scale := Vector2.ONE * (1.06 if active else 1.0)
	hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale", target_scale, 0.12)


func play_spawn_animation(from_left: bool) -> void:
	if motion_tween != null:
		motion_tween.kill()
	scale = Vector2.ONE * 0.9
	modulate = Color(1, 1, 1, 0)
	rotation_degrees = -5.0 if from_left else 5.0
	motion_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
	motion_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.18)
	motion_tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.2)


func play_pulse_animation() -> void:
	if motion_tween != null:
		motion_tween.kill()
	motion_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "scale", Vector2.ONE * 1.1, 0.12)
	motion_tween.tween_property(self, "scale", Vector2.ONE, 0.14)


func _set_children_mouse_filter(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_filter(child)
