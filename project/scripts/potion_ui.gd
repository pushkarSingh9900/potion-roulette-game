extends Control
class_name PotionUI

signal potion_filled(cards: Array[GameRules.CardType])

@onready var slot1 = $CardSlots/Slot1
@onready var slot2 = $CardSlots/Slot2

var current_cards: Array[GameRules.CardType] = []

func _ready():
	slot1.card_dropped.connect(_on_card_dropped)
	slot2.card_dropped.connect(_on_card_dropped)

func _on_card_dropped(card_data: CardData):
	current_cards.append(card_data.type)
	if current_cards.size() == 2:
		# Potion is full
		potion_filled.emit(current_cards)
