extends Control
class_name CardUI

var card_data: CardData

@onready var background = $Background
@onready var icon = $Icon
@onready var description_label = $Description

func setup(data: CardData):
	card_data = data
	description_label.text = data.description
	
	# Set visual colors based on type
	match data.type:
		GameRules.CardType.FIRE:
			background.color = Color(0.3, 0.05, 0.05, 1) # Dark red
			description_label.text = "FIRE"
		GameRules.CardType.POISON:
			background.color = Color(0.1, 0.3, 0.1, 1) # Dark green
			description_label.text = "POISON"
		GameRules.CardType.HEAL:
			background.color = Color(0.1, 0.2, 0.3, 1) # Dark cyan
			description_label.text = "HEAL"
		GameRules.CardType.CHAOS:
			background.color = Color(0.2, 0.05, 0.3, 1) # Dark purple
			description_label.text = "CHAOS"

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
