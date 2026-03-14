extends Node

# AI logic for crafting and choosing potions
static func craft_potions(ai_player: Player) -> Array[Array]:
	# Simple AI strategy:
	# 1. Look for highest damage combo
	# 2. Put it in one potion
	# 3. Put "trash" or duds in the other to bluff
	
	var hand = ai_player.hand.duplicate()
	var potion1: Array[GameRules.CardType] = []
	var potion2: Array[GameRules.CardType] = []
	
	# Very basic placeholder logic: just pick first 4 cards
	if hand.size() >= 4:
		potion1.append(hand.pop_at(0))
		potion1.append(hand.pop_at(0))
		potion2.append(hand.pop_at(0))
		potion2.append(hand.pop_at(0))
	elif hand.size() >= 2:
		potion1.append(hand.pop_at(0))
		potion1.append(hand.pop_at(0))
		
	ai_player.hand = hand
	return [potion1, potion2]

static func choose_potion(offered_potions: Array[Array]) -> int:
	# AI Choice strategy: 
	# Randomly pick if no peek ability, or use peek if available
	return randi() % offered_potions.size()
