extends Control
class_name PotionSlot

signal card_dropped(card_data)

var held_card_data: CardData = null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is CardUI and held_card_data == null

func _drop_data(at_position: Vector2, data: Variant):
	if data is CardUI:
		held_card_data = data.card_data
		
		# Visually show a tiny colored rectangle inside the slot to represent the dropped card
		var rect = ColorRect.new()
		rect.set_anchors_preset(PRESET_FULL_RECT)
		rect.color = data.background.color
		add_child(rect)
		
		# Reparent or hide the dragged source card
		data.queue_free() # For simplicity, we consume the UI node completely.
		
		card_dropped.emit(held_card_data)
