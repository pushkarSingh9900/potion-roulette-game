extends Node

# Resolves a potion (2 cards) into an effect
static func resolve_potion(cards: Array[GameRules.CardType]) -> Dictionary:
	if cards.size() != 2:
		return {"effect": "nothing", "value": 0, "target": "none"}
	
	# Sort cards to match combo keys
	var sorted_cards = cards.duplicate()
	sorted_cards.sort()
	
	# Check for combo
	for combo_key in GameRules.COMBOS.keys():
		if combo_key[0] == sorted_cards[0] and combo_key[1] == sorted_cards[1]:
			return GameRules.COMBOS[combo_key]
	
	return {"effect": "nothing", "value": 0, "target": "none"}

# Chaos Wheel resolver
static func roll_chaos_wheel() -> GameRules.ChaosOutcome:
	var roll = randi() % 6
	return roll as GameRules.ChaosOutcome
