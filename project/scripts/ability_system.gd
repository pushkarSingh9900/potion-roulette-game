extends Node

static func perform_ability_roll(p1: Player, p2: Player):
	# Both players get a roll
	_roll_for_player(p1)
	_roll_for_player(p2)

static func _roll_for_player(player: Player):
	if randf() > 0.5:
		# Draw a random non-chaos card
		var card = _get_random_card()
		player.hand.append(card)
	else:
		# Gain a Partial Peek ability
		player.abilities.append("peek")

static func _get_random_card() -> GameRules.CardType:
	var types = [GameRules.CardType.FIRE, GameRules.CardType.POISON, GameRules.CardType.HEAL]
	return types[randi() % types.size()]
