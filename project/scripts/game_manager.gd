extends Control

enum Ingredient {
	FIRE,
	POISON,
	HEAL,
	CHAOS,
}

const MAX_HEALTH := 10
const CARD_POOL := [
	Ingredient.FIRE,
	Ingredient.FIRE,
	Ingredient.POISON,
	Ingredient.POISON,
	Ingredient.HEAL,
	Ingredient.HEAL,
	Ingredient.HEAL,
	Ingredient.CHAOS,
	Ingredient.CHAOS,
	Ingredient.CHAOS,
	Ingredient.CHAOS,
	Ingredient.CHAOS,
]

var rng := RandomNumberGenerator.new()
var player_health := MAX_HEALTH
var ai_health := MAX_HEALTH
var turn := 1
var is_player_turn := true
var game_over := false
var potion_a := []
var potion_b := []
var result_text := ""


func _ready() -> void:
	rng.randomize()
	$PotionA.pressed.connect(_on_potion_a_pressed)
	$PotionB.pressed.connect(_on_potion_b_pressed)
	$ResultLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_start_match()


func _start_match() -> void:
	player_health = MAX_HEALTH
	ai_health = MAX_HEALTH
	turn = 1
	game_over = false
	is_player_turn = rng.randi_range(0, 1) == 0
	result_text = "%s won the toss and chooses first." % _chooser_name()
	_roll_hidden_potions()
	update_ui()
	if not is_player_turn:
		call_deferred("_run_ai_turn")


func update_ui() -> void:
	$PlayerHealth.text = "Player HP: %d" % player_health
	$AIHealth.text = "Bot HP: %d" % ai_health
	if game_over:
		$TurnLabel.text = "Game Over"
	else:
		$TurnLabel.text = "Turn: %d - %s chooses" % [turn, _chooser_name()]
	$ResultLabel.text = result_text
	$PotionA.disabled = game_over or not is_player_turn
	$PotionB.disabled = game_over or not is_player_turn


func _on_potion_a_pressed() -> void:
	if game_over or not is_player_turn:
		return
	_resolve_turn(0)


func _on_potion_b_pressed() -> void:
	if game_over or not is_player_turn:
		return
	_resolve_turn(1)


func _run_ai_turn() -> void:
	if game_over or is_player_turn:
		return
	update_ui()
	await get_tree().create_timer(1.0).timeout
	if game_over or is_player_turn:
		return
	_resolve_turn(rng.randi_range(0, 1))


func _resolve_turn(chosen_index: int) -> void:
	var potions: Array = [potion_a, potion_b]
	var targets := ["", ""]
	var chooser_target := _chooser_target()
	var other_target := _other_target(chooser_target)

	targets[chosen_index] = chooser_target
	targets[1 - chosen_index] = other_target

	var effect_a := _apply_potion_effect(potions[0], targets[0])
	var effect_b := _apply_potion_effect(potions[1], targets[1])

	$PotionA.text = "Potion A: %s" % _potion_text(potion_a)
	$PotionB.text = "Potion B: %s" % _potion_text(potion_b)

	result_text = "%s chose Potion %s.\nPotion A (%s) hit %s: %s\nPotion B (%s) hit %s: %s" % [
		_chooser_name(),
		_potion_name(chosen_index),
		_potion_text(potion_a),
		_target_name(targets[0]),
		effect_a,
		_potion_text(potion_b),
		_target_name(targets[1]),
		effect_b,
	]

	_finish_turn()


func _finish_turn() -> void:
	_check_game_over()
	update_ui()
	if game_over:
		return

	turn += 1
	is_player_turn = not is_player_turn
	_roll_hidden_potions()
	update_ui()
	if not is_player_turn:
		call_deferred("_run_ai_turn")


func _roll_hidden_potions() -> void:
	var bag := CARD_POOL.duplicate()
	var drawn := []

	for _i in range(4):
		var draw_index := rng.randi_range(0, bag.size() - 1)
		drawn.append(bag[draw_index])
		bag.remove_at(draw_index)

	potion_a = [drawn[0], drawn[1]]
	potion_b = [drawn[2], drawn[3]]
	$PotionA.text = "Potion A"
	$PotionB.text = "Potion B"


func _apply_potion_effect(potion: Array, intended_target: String) -> String:
	var sorted_potion := potion.duplicate()
	sorted_potion.sort()

	if sorted_potion == [Ingredient.FIRE, Ingredient.FIRE]:
		var fire_damage := _damage_target(intended_target, 2)
		return "takes %d damage" % fire_damage
	if sorted_potion == [Ingredient.POISON, Ingredient.POISON]:
		var poison_damage := _damage_target(intended_target, 2)
		return "takes %d damage" % poison_damage
	if sorted_potion == [Ingredient.FIRE, Ingredient.POISON]:
		var combo_damage := _damage_target(intended_target, 3)
		return "takes %d damage" % combo_damage
	if sorted_potion == [Ingredient.HEAL, Ingredient.HEAL]:
		var heal_amount := _heal_target(intended_target, 2)
		return "heals %d HP" % heal_amount
	if sorted_potion == [Ingredient.CHAOS, Ingredient.HEAL]:
		var random_heal_target := _random_target()
		var random_heal_amount := _heal_target(random_heal_target, 1)
		return "%s heals %d HP" % [_target_name(random_heal_target), random_heal_amount]
	if sorted_potion == [Ingredient.CHAOS, Ingredient.FIRE]:
		var random_damage_target := _random_target()
		var random_damage_amount := _damage_target(random_damage_target, 1)
		return "%s takes %d damage" % [_target_name(random_damage_target), random_damage_amount]
	if sorted_potion == [Ingredient.CHAOS, Ingredient.CHAOS]:
		return _resolve_chaos_chaos()
	return "no effect"


func _resolve_chaos_chaos() -> String:
	var random_target := _random_target()
	var roll := rng.randi_range(0, 2)

	if roll == 0:
		var damage := _damage_target(random_target, 2)
		return "%s takes %d damage" % [_target_name(random_target), damage]
	if roll == 1:
		var heal := _heal_target(random_target, 2)
		return "%s heals %d HP" % [_target_name(random_target), heal]
	return "%s is unaffected" % _target_name(random_target)


func _damage_target(target: String, amount: int) -> int:
	var before := _get_health(target)
	_set_health(target, max(0, before - amount))
	return before - _get_health(target)


func _heal_target(target: String, amount: int) -> int:
	var before := _get_health(target)
	_set_health(target, min(MAX_HEALTH, before + amount))
	return _get_health(target) - before


func _get_health(target: String) -> int:
	if target == "player":
		return player_health
	return ai_health


func _set_health(target: String, value: int) -> void:
	if target == "player":
		player_health = value
	else:
		ai_health = value


func _check_game_over() -> void:
	if player_health <= 0 and ai_health <= 0:
		game_over = true
		result_text += "\nResult: draw."
	elif player_health <= 0:
		game_over = true
		result_text += "\nResult: Bot wins."
	elif ai_health <= 0:
		game_over = true
		result_text += "\nResult: Player wins."


func _chooser_name() -> String:
	if is_player_turn:
		return "Player"
	return "Bot"


func _chooser_target() -> String:
	if is_player_turn:
		return "player"
	return "ai"


func _other_target(target: String) -> String:
	if target == "player":
		return "ai"
	return "player"


func _random_target() -> String:
	if rng.randi_range(0, 1) == 0:
		return "player"
	return "ai"


func _target_name(target: String) -> String:
	if target == "player":
		return "Player"
	return "Bot"


func _potion_name(index: int) -> String:
	if index == 0:
		return "A"
	return "B"


func _potion_text(potion: Array) -> String:
	return "%s + %s" % [_ingredient_name(potion[0]), _ingredient_name(potion[1])]


func _ingredient_name(ingredient: int) -> String:
	match ingredient:
		Ingredient.FIRE:
			return "Fire"
		Ingredient.POISON:
			return "Poison"
		Ingredient.HEAL:
			return "Heal"
		Ingredient.CHAOS:
			return "Chaos"
	return "Unknown"
