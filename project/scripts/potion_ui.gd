extends Control
class_name PotionUI

const ART_ASSETS := preload("res://scripts/art_assets.gd")

signal potion_filled(cards: Array[GameRules.CardType])

const POTION_TEXTURES := [
	preload("res://assets/sprites/potions/freepotion1.png"),
	preload("res://assets/sprites/potions/freepotion2.png"),
	preload("res://assets/sprites/potions/freepotion3.png"),
	preload("res://assets/sprites/potions/freepotion4.png"),
]

var current_cards: Array = []
var motion_tween: Tween

func _ready():
	var slot1 = $CardSlots/Slot1
	var slot2 = $CardSlots/Slot2
	slot1.card_dropped.connect(_on_card_dropped)
	slot2.card_dropped.connect(_on_card_dropped)
	_update_bottle_art()


func set_title(text: String) -> void:
	$Label.text = text
	_update_bottle_art()


func clear_slots() -> void:
	current_cards.clear()
	var slot1 = $CardSlots/Slot1
	var slot2 = $CardSlots/Slot2
	_clear_slot(slot1)
	_clear_slot(slot2)


func display_cards(cards: Array, reveal := true) -> void:
	clear_slots()
	current_cards = cards.duplicate()
	$BottleSprite.color = Color(0, 0, 0, 0)
	$BottleArt.modulate = Color(1, 1, 1, 0.82) if reveal else Color(0.42, 0.42, 0.46, 0.28)

	var slot1 = $CardSlots/Slot1
	var slot2 = $CardSlots/Slot2
	var slots = [slot1, slot2]
	for index in range(slots.size()):
		if index < cards.size():
			_populate_slot(slots[index], cards[index], reveal)
	_play_motion(reveal)


func _clear_slot(slot: Control) -> void:
	if slot is PotionSlot:
		slot.held_card_data = null
	for child in slot.get_children():
		child.queue_free()


func _populate_slot(slot: Control, card_type: int, reveal: bool) -> void:
	var art := TextureRect.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 0
	art.offset_top = 0
	art.offset_right = 0
	art.offset_bottom = 0
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _card_texture(card_type) if reveal else null
	art.modulate = Color(1, 1, 1, 1) if reveal else Color(0.4, 0.4, 0.45, 0.8)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(art)

	if not reveal:
		var veil := ColorRect.new()
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.color = Color(0.12, 0.12, 0.16, 0.72)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(veil)

		var label := Label.new()
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = "?"
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)


func _update_bottle_art() -> void:
	var title: String = $Label.text
	var art_index: int = 0 if title.ends_with("A") else 1
	$BottleArt.texture = POTION_TEXTURES[art_index]


func _card_texture(card_type: int) -> Texture2D:
	return ART_ASSETS.get_card_texture(card_type)


func play_bounce() -> void:
	_play_motion(true)


func _play_motion(reveal: bool) -> void:
	if motion_tween != null:
		motion_tween.kill()
	scale = Vector2.ONE * (0.96 if reveal else 0.92)
	modulate = Color(1, 1, 1, 0.82 if reveal else 0.68)
	motion_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)
	motion_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.22)


func _on_card_dropped(card_data: CardData):
	current_cards.append(card_data.type)
	if current_cards.size() == 2:
		# Potion is full
		potion_filled.emit(current_cards)
