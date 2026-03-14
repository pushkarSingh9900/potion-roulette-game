extends Node

# Handles the effects of the Chaos Wheel outcomes
static func apply_chaos_outcome(outcome: GameRules.ChaosOutcome, active_player: Player, opponent_player: Player):
	match outcome:
		GameRules.ChaosOutcome.HP_SWAP:
			var temp_hp = active_player.hp
			active_player.hp = opponent_player.hp
			opponent_player.hp = temp_hp
		
		GameRules.ChaosOutcome.FRIENDLY_FIRE_2:
			active_player.take_damage(2)
			
		GameRules.ChaosOutcome.TOXIC_CLOUD_1_1:
			active_player.take_damage(1)
			opponent_player.take_damage(1)
			
		GameRules.ChaosOutcome.ALCHEMISTS_GIFT:
			# Placeholder for drawing cards for both
			pass
			
		GameRules.ChaosOutcome.STEAL_CARD:
			# Placeholder for stealing a random card
			pass
			
		GameRules.ChaosOutcome.MIRACLE_HEAL_3:
			# Victim of the potion (opponent of brewer) heals 3
			opponent_player.heal(3)
