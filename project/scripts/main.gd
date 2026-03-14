extends Control

const MAX_HP := 10
const INGREDIENTS_PER_TURN := 4
const MAX_LOG_LINES := 8

enum Ingredient {
	FIRE,
	POISON,
	HEAL,
	CHAOS,
}

enum Phase {
	PASS_TO_ACTIVE,
	CRAFT,
	PASS_TO_CHOOSER,
	CHOOSE,
	GAME_OVER,
}

var rng := RandomNumberGenerator.new()
var players := []
var active_player := 0
var turn_number := 0
var phase := Phase.PASS_TO_ACTIVE
var current_ingredients := []
var selected_ingredient_indexes := []
var brewed_potions := []
var winner_text := ""
var log_lines := []

var title_label: Label
var hp_label: Label
var instructions_label: Label
var selection_label: Label
var ingredient_container: HBoxContainer
var choice_container: HBoxContainer
var primary_button: Button
var secondary_button: Button
var log_label: Label


func _ready() -> void:
	rng.randomize()
	_reset_match()
	_build_ui()
	_update_ui()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)

	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hp_label)

	instructions_label = Label.new()
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(instructions_label)

	selection_label = Label.new()
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(selection_label)

	ingredient_container = HBoxContainer.new()
	ingredient_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ingredient_container.add_theme_constant_override("separation", 8)
	root.add_child(ingredient_container)

	choice_container = HBoxContainer.new()
	choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_container.add_theme_constant_override("separation", 8)
	root.add_child(choice_container)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)

	primary_button = Button.new()
	primary_button.pressed.connect(_on_primary_button_pressed)
	action_row.add_child(primary_button)

	secondary_button = Button.new()
	secondary_button.pressed.connect(_on_secondary_button_pressed)
	action_row.add_child(secondary_button)

	log_label = Label.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	root.add_child(log_label)


func _reset_match() -> void:
	players = [
		_make_player("Player 1"),
		_make_player("Player 2"),
	]
	active_player = 0
	turn_number = 0
	phase = Phase.PASS_TO_ACTIVE
	current_ingredients = []
	selected_ingredient_indexes = []
	brewed_potions = []
	winner_text = ""
	log_lines = ["Potions Roulette ready."]


func _make_player(name: String) -> Dictionary:
	return {
		"name": name,
		"hp": MAX_HP,
		"pending_poison": 0,
	}


func _on_primary_button_pressed() -> void:
	match phase:
		Phase.PASS_TO_ACTIVE:
			_start_turn()
		Phase.CRAFT:
			if selected_ingredient_indexes.size() == INGREDIENTS_PER_TURN:
				_lock_potions()
		Phase.PASS_TO_CHOOSER:
			phase = Phase.CHOOSE
			_update_ui()
		Phase.GAME_OVER:
			_reset_match()
			_update_ui()


func _on_secondary_button_pressed() -> void:
	if phase == Phase.CRAFT:
		selected_ingredient_indexes.clear()
		_update_ui()


func _start_turn() -> void:
	turn_number += 1
	_apply_pending_poison(active_player)
	if phase == Phase.GAME_OVER:
		_update_ui()
		return

	current_ingredients = _roll_ingredients()
	selected_ingredient_indexes.clear()
	brewed_potions.clear()
	phase = Phase.CRAFT
	_log("%s starts turn %d." % [_player_name(active_player), turn_number])
	_update_ui()


func _apply_pending_poison(player_index: int) -> void:
	var poison := int(players[player_index]["pending_poison"])
	if poison <= 0:
		return

	players[player_index]["pending_poison"] = 0
	_deal_damage(player_index, poison, "Lingering Poison")
	_check_for_game_over()


func _roll_ingredients() -> Array:
	var result := []
	for _i in range(INGREDIENTS_PER_TURN):
		result.append(rng.randi_range(0, Ingredient.CHAOS))
	return result


func _lock_potions() -> void:
	var first := [
		current_ingredients[selected_ingredient_indexes[0]],
		current_ingredients[selected_ingredient_indexes[1]],
	]
	var second := [
		current_ingredients[selected_ingredient_indexes[2]],
		current_ingredients[selected_ingredient_indexes[3]],
	]
	brewed_potions = [first, second]
	phase = Phase.PASS_TO_CHOOSER
	_log("%s brewed two potions." % _player_name(active_player))
	_update_ui()


func _on_ingredient_pressed(index: int) -> void:
	if phase != Phase.CRAFT:
		return
	if selected_ingredient_indexes.has(index):
		return
	if selected_ingredient_indexes.size() >= INGREDIENTS_PER_TURN:
		return

	selected_ingredient_indexes.append(index)
	_update_ui()


func _on_choose_potion(index: int) -> void:
	if phase != Phase.CHOOSE:
		return

	var drinker := 1 - active_player
	_log("%s chose Potion %s." % [_player_name(drinker), _potion_name(index)])
	_resolve_potion(index)

	if _check_for_game_over():
		_update_ui()
		return

	active_player = drinker
	phase = Phase.PASS_TO_ACTIVE
	current_ingredients = []
	selected_ingredient_indexes.clear()
	brewed_potions.clear()
	_update_ui()


func _resolve_potion(index: int) -> void:
	var brewer := active_player
	var drinker := 1 - active_player
	var potion := brewed_potions[index]
	var sorted_potion := potion.duplicate()
	sorted_potion.sort()

	_log("Potion %s was %s." % [_potion_name(index), _potion_text(potion)])

	if sorted_potion == [Ingredient.FIRE, Ingredient.FIRE]:
		_deal_damage(drinker, 2, "Fire + Fire")
	elif sorted_potion == [Ingredient.POISON, Ingredient.POISON]:
		_deal_damage(drinker, 2, "Poison + Poison")
	elif sorted_potion == [Ingredient.FIRE, Ingredient.POISON]:
		_deal_damage(drinker, 3, "Fire + Poison")
	elif sorted_potion == [Ingredient.HEAL, Ingredient.HEAL]:
		_heal_player(drinker, 2, "Heal + Heal")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.HEAL]:
		var heal_target := rng.randi_range(0, 1)
		_heal_player(heal_target, 1, "Heal + Chaos")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.FIRE]:
		var damage_target := rng.randi_range(0, 1)
		_deal_damage(damage_target, 1, "Fire + Chaos")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.POISON]:
		_deal_damage(drinker, 1, "Poison + Chaos")
		players[drinker]["pending_poison"] += 1
		_log("%s is poisoned for next turn." % _player_name(drinker))
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.CHAOS]:
		_resolve_chaos_event(brewer, drinker)
	else:
		_log("The mixture fizzles and does nothing.")


func _resolve_chaos_event(brewer: int, drinker: int) -> void:
	var roll := rng.randi_range(1, 6)
	_log("Chaos + Chaos rolled %d." % roll)

	match roll:
		1:
			var brewer_hp := int(players[brewer]["hp"])
			var drinker_hp := int(players[drinker]["hp"])
			players[brewer]["hp"] = drinker_hp
			players[drinker]["hp"] = brewer_hp
			_log("HP Swap.")
		2:
			_deal_damage(drinker, 2, "Friendly Fire")
		3:
			_deal_damage(0, 1, "Toxic Cloud")
			_deal_damage(1, 1, "Toxic Cloud")
		4:
			_heal_player(brewer, 1, "Alchemist's Gift")
		5:
			_heal_player(1 - brewer, 1, "Thief's Brew")
		6:
			_heal_player(drinker, 3, "Miracle Brew")


func _deal_damage(player_index: int, amount: int, source: String) -> void:
	players[player_index]["hp"] = max(0, int(players[player_index]["hp"]) - amount)
	_log("%s takes %d damage from %s." % [_player_name(player_index), amount, source])


func _heal_player(player_index: int, amount: int, source: String) -> void:
	var current_hp := int(players[player_index]["hp"])
	var healed_hp := min(MAX_HP, current_hp + amount)
	var recovered := healed_hp - current_hp
	players[player_index]["hp"] = healed_hp
	_log("%s heals %d from %s." % [_player_name(player_index), recovered, source])


func _check_for_game_over() -> bool:
	var player_one_hp := int(players[0]["hp"])
	var player_two_hp := int(players[1]["hp"])

	if player_one_hp <= 0 and player_two_hp <= 0:
		winner_text = "Draw"
	elif player_one_hp <= 0:
		winner_text = "Player 2 wins"
	elif player_two_hp <= 0:
		winner_text = "Player 1 wins"
	else:
		return false

	phase = Phase.GAME_OVER
	_log("Game over: %s." % winner_text)
	return true


func _update_ui() -> void:
	title_label.text = "Potions Roulette"
	hp_label.text = "Player 1 HP: %d    Player 2 HP: %d" % [
		int(players[0]["hp"]),
		int(players[1]["hp"]),
	]
	selection_label.text = _selection_text()
	log_label.text = "Event Log\n" + _join_strings(log_lines, "\n")

	_clear_container(ingredient_container)
	_clear_container(choice_container)

	primary_button.visible = true
	secondary_button.visible = false
	primary_button.disabled = false

	match phase:
		Phase.PASS_TO_ACTIVE:
			instructions_label.text = "Pass the device to %s. Press Start Turn when ready." % _player_name(active_player)
			primary_button.text = "Start Turn"
		Phase.CRAFT:
			instructions_label.text = "%s: click the four ingredients in the order you want to pair them." % _player_name(active_player)
			primary_button.text = "Brew Potions"
			primary_button.disabled = selected_ingredient_indexes.size() != INGREDIENTS_PER_TURN
			secondary_button.visible = true
			secondary_button.text = "Reset Pairing"
			_build_ingredient_buttons()
		Phase.PASS_TO_CHOOSER:
			instructions_label.text = "Pass the device to %s. Press Reveal Choices when ready." % _player_name(1 - active_player)
			primary_button.text = "Reveal Choices"
		Phase.CHOOSE:
			instructions_label.text = "%s: pick one potion to drink." % _player_name(1 - active_player)
			primary_button.visible = false
			_build_choice_buttons()
		Phase.GAME_OVER:
			instructions_label.text = "%s. Press New Match to restart." % winner_text
			primary_button.text = "New Match"


func _build_ingredient_buttons() -> void:
	for index in range(current_ingredients.size()):
		var button := Button.new()
		var ingredient_name := _ingredient_name(current_ingredients[index])
		if selected_ingredient_indexes.has(index):
			button.text = "%d. %s [selected]" % [index + 1, ingredient_name]
			button.disabled = true
		else:
			button.text = "%d. %s" % [index + 1, ingredient_name]
			button.pressed.connect(Callable(self, "_on_ingredient_pressed").bind(index))
		ingredient_container.add_child(button)


func _build_choice_buttons() -> void:
	for index in range(brewed_potions.size()):
		var button := Button.new()
		button.text = "Choose Potion %s" % _potion_name(index)
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(Callable(self, "_on_choose_potion").bind(index))
		choice_container.add_child(button)


func _selection_text() -> String:
	match phase:
		Phase.CRAFT:
			var first_pair := _pair_preview(0, 2)
			var second_pair := _pair_preview(2, 4)
			return "Potion A: %s\nPotion B: %s" % [first_pair, second_pair]
		Phase.PASS_TO_CHOOSER, Phase.CHOOSE:
			if brewed_potions.size() == 2:
				return "%s built Potion A and Potion B. Their contents stay hidden until a choice is made." % _player_name(active_player)
		Phase.GAME_OVER:
			return "Final Score: Player 1 %d, Player 2 %d" % [
				int(players[0]["hp"]),
				int(players[1]["hp"]),
			]
	return "MVP build: hotseat only, two hidden potions per turn."


func _pair_preview(start_index: int, end_index: int) -> String:
	var names := []
	for i in range(start_index, min(end_index, selected_ingredient_indexes.size())):
		names.append(_ingredient_name(current_ingredients[selected_ingredient_indexes[i]]))
	if names.is_empty():
		return "[empty]"
	return _join_strings(names, " + ")


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


func _potion_name(index: int) -> String:
	if index == 0:
		return "A"
	return "B"


func _potion_text(potion: Array) -> String:
	return "%s + %s" % [_ingredient_name(potion[0]), _ingredient_name(potion[1])]


func _player_name(player_index: int) -> String:
	return str(players[player_index]["name"])


func _log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > MAX_LOG_LINES:
		log_lines.pop_front()


func _join_strings(parts: Array, separator: String) -> String:
	var result := ""
	for index in range(parts.size()):
		result += str(parts[index])
		if index < parts.size() - 1:
			result += separator
	return result


func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()
