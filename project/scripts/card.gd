extends Resource
class_name CardData

@export var type: GameRules.CardType
@export var texture: Texture2D
@export var description: String

func _init(p_type = GameRules.CardType.CHAOS):
	type = p_type
	match type:
		GameRules.CardType.FIRE:
			description = "Brew for aggression."
		GameRules.CardType.POISON:
			description = "A toxic sting."
		GameRules.CardType.HEAL:
			description = "Sweet relief."
		GameRules.CardType.CHAOS:
			description = "Embrace the unknown."
