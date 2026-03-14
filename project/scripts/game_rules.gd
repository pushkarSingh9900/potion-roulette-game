extends Node

# Card Types
enum CardType {
	FIRE,
	POISON,
	HEAL,
	CHAOS
}

# Game Constants
const STARTING_HP_P1 = 10
const STARTING_HP_P2 = 11 # Compensate for going second
const MAX_HP = 10
const DRAW_PER_TURN = 1
const ABILITY_ROLL_INTERVAL = 3

# Combo Table
# Format: [Card1, Card2] sorted alphabetically -> {effect: String, value: int, target: String}
const COMBOS = {
	[CardType.FIRE, CardType.FIRE]: {"effect": "damage", "value": 2, "target": "opponent"},
	[CardType.POISON, CardType.POISON]: {"effect": "damage", "value": 2, "target": "opponent"},
	[CardType.FIRE, CardType.POISON]: {"effect": "damage", "value": 3, "target": "opponent"},
	[CardType.HEAL, CardType.HEAL]: {"effect": "heal", "value": 2, "target": "self"},
	[CardType.CHAOS, CardType.HEAL]: {"effect": "heal", "value": 1, "target": "random"},
	[CardType.CHAOS, CardType.FIRE]: {"effect": "damage", "value": 1, "target": "random"},
	[CardType.CHAOS, CardType.POISON]: {"effect": "lingering_poison", "value": 1, "target": "opponent"},
	[CardType.CHAOS, CardType.CHAOS]: {"effect": "chaos_wheel", "value": 0, "target": "dynamic"},
	[CardType.FIRE, CardType.HEAL]: {"effect": "nothing", "value": 0, "target": "none"},
	[CardType.POISON, CardType.HEAL]: {"effect": "nothing", "value": 0, "target": "none"}
}

# Chaos Wheel Outcomes
enum ChaosOutcome {
	HP_SWAP,
	FRIENDLY_FIRE_2,
	TOXIC_CLOUD_1_1,
	ALCHEMISTS_GIFT,
	STEAL_CARD,
	MIRACLE_HEAL_3
}
