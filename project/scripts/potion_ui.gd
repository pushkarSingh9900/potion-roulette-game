extends Control
class_name PotionUI

signal potion_filled(cards: Array[GameRules.CardType])

@onready var slot1 = $CardSlots/Slot1
@onready var slot2 = $CardSlots/Slot2
@onready var title_label = $Label
@onready var bottle_sprite = $BottleSprite

var current_cards: Array[GameRules.CardType] = []

func _ready():
	slot1.card_dropped.connect(_on_card_dropped)
	slot2.card_dropped.connect(_on_card_dropped)


func set_title(text: String) -> void:
	title_label.text = text


func clear_slots() -> void:
	current_cards.clear()
	_clear_slot(slot1)
	_clear_slot(slot2)


func display_cards(cards: Array, reveal := true) -> void:
	clear_slots()
	current_cards = cards.duplicate()
	bottle_sprite.color = Color(0.18, 0.12, 0.24, 1) if reveal else Color(0.08, 0.08, 0.12, 1)

	var slots = [slot1, slot2]
	for index in range(slots.size()):
		if index < cards.size():
			_populate_slot(slots[index], cards[index], reveal)


func _clear_slot(slot: Control) -> void:
	if slot is PotionSlot:
		slot.held_card_data = null
	for child in slot.get_children():
		child.queue_free()


func _populate_slot(slot: Control, card_type: int, reveal: bool) -> void:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = _card_color(card_type) if reveal else Color(0.22, 0.22, 0.25, 1)
	slot.add_child(rect)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = _card_name(card_type) if reveal else "?"
	slot.add_child(label)


func _card_color(card_type: int) -> Color:
	match card_type:
		GameRules.CardType.FIRE:
			return Color(0.4, 0.1, 0.08, 1)
		GameRules.CardType.POISON:
			return Color(0.12, 0.35, 0.12, 1)
		GameRules.CardType.HEAL:
			return Color(0.12, 0.28, 0.35, 1)
		GameRules.CardType.CHAOS:
			return Color(0.28, 0.12, 0.4, 1)
	return Color(0.18, 0.18, 0.2, 1)


func _card_name(card_type: int) -> String:
	match card_type:
		GameRules.CardType.FIRE:
			return "Fire"
		GameRules.CardType.POISON:
			return "Poison"
		GameRules.CardType.HEAL:
			return "Heal"
		GameRules.CardType.CHAOS:
			return "Chaos"
	return "?"

func _on_card_dropped(card_data: CardData):
	current_cards.append(card_data.type)
	if current_cards.size() == 2:
		# Potion is full
		potion_filled.emit(current_cards)
