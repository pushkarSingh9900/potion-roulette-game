extends Node
class_name Player

signal hp_changed(new_hp)
signal shield_changed(has_shield)
signal lingering_poison_changed(is_poisoned)

var hp: int:
	set(value):
		hp = clamp(value, 0, GameRules.MAX_HP + 1) # Allow 11 for P2 start, but usually clamp to 10
		hp_changed.emit(hp)

var has_shield: bool = false:
	set(value):
		has_shield = value
		shield_changed.emit(has_shield)

var lingering_poison: bool = false:
	set(value):
		lingering_poison = value
		lingering_poison_changed.emit(lingering_poison)

var hand: Array[GameRules.CardType] = []
var abilities: Array[String] = [] # "peek", etc.
var is_ai: bool = false

func _ready():
	hp = GameRules.STARTING_HP_P1 if not is_ai else GameRules.STARTING_HP_P1 # Default

func take_damage(amount: int):
	if amount <= 0: return
	
	if has_shield:
		has_shield = false # Shield absorbs 1 damage hit entirely
		return
		
	hp -= amount
	# Trigger VFX (assumes VFXManager is added to AutoLoads or accessed globally; assuming global for now)
	if has_node("/root/VfxManager"):
		get_node("/root/VfxManager").add_screen_shake(1.0)
		# NOTE: We can't spawn damage numbers cleanly here without a UI reference,
		# so we let main.gd handle the floating numbers.

func heal(amount: int):
	if amount <= 0: return
	
	var overflow = (hp + amount) - GameRules.MAX_HP
	if overflow > 0:
		hp = GameRules.MAX_HP
		has_shield = true # Over-heal grants shield
	else:
		hp += amount

func apply_lingering_poison():
	if lingering_poison:
		take_damage(1)
		lingering_poison = false
