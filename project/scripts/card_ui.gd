extends Control
class_name CardUI

signal card_selected(card_ui: CardUI)

var card_data: CardData
var card_index := -1
var is_clickable := false
var is_selected := false
var is_face_down := false

@onready var background = $Background
@onready var border = $Border
@onready var icon = $Icon
@onready var description_label = $Description

func setup(data: CardData):
	card_data = data
	_refresh_visuals()


func set_card_index(value: int) -> void:
	card_index = value


func set_clickable(value: bool) -> void:
	is_clickable = value
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW


func set_selected(value: bool) -> void:
	is_selected = value
	_refresh_visuals()


func set_face_down(value: bool) -> void:
	is_face_down = value
	_refresh_visuals()


func _refresh_visuals() -> void:
	if is_face_down or card_data == null:
		background.color = Color(0.12, 0.12, 0.14, 1)
		description_label.text = "HIDDEN"
	else:
		match card_data.type:
			GameRules.CardType.FIRE:
				background.color = Color(0.3, 0.05, 0.05, 1)
				description_label.text = "FIRE"
			GameRules.CardType.POISON:
				background.color = Color(0.1, 0.3, 0.1, 1)
				description_label.text = "POISON"
			GameRules.CardType.HEAL:
				background.color = Color(0.1, 0.2, 0.3, 1)
				description_label.text = "HEAL"
			GameRules.CardType.CHAOS:
				background.color = Color(0.2, 0.05, 0.3, 1)
				description_label.text = "CHAOS"

	border.border_color = Color(0.95, 0.85, 0.45, 1) if is_selected else Color(0.4, 0.4, 0.4, 1)
	border.border_width = 4.0 if is_selected else 2.0
	icon.visible = false


func _gui_input(event: InputEvent) -> void:
	if not is_clickable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit(self)

# Drag and Drop functionality
func _get_drag_data(at_position: Vector2):
	if card_data == null: return null
	
	var preview = Control.new()
	var rect = ColorRect.new()
	rect.size = size
	rect.color = background.color
	rect.modulate = Color(1, 1, 1, 0.5) # Semi-transparent preview
	preview.add_child(rect)
	
	# Center the preview on the mouse
	set_drag_preview(preview)
	
	return self # Return the CardUI node as data
