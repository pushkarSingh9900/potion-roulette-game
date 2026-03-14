extends Control

const MAX_HP := 10
const INGREDIENTS_PER_TURN := 4
const MAX_LOG_LINES := 6

# Color Palette ("Dark Alchemy")
const COLOR_BG_VOID := Color("#0A0A0A")
const COLOR_BG_SURFACE := Color("#1A1A1A")
const COLOR_TEXT_PRIMARY := Color("#D4D4D4")
const COLOR_TEXT_MUTED := Color("#666666")
const COLOR_FIRE := Color("#CC0000")
const COLOR_POISON := Color("#44CC44")
const COLOR_HEAL := Color("#33CCCC")
const COLOR_CHAOS := Color("#9933CC")

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

# UI References
var title_label: Label
var hp_bar_p1: ProgressBar
var hp_bar_p2: ProgressBar
var instructions_label: Label
var selection_label: Label
var ingredient_container: HBoxContainer
var choice_container: HBoxContainer
var primary_button: Button
var secondary_button: Button
var log_label: RichTextLabel
var center_panel: PanelContainer
var screen_flash: ColorRect

func _ready() -> void:
	rng.randomize()
	_build_ui()
	_reset_match()
	_update_ui()

func _build_ui() -> void:
	# Base Void Background
	var bg = ColorRect.new()
	bg.color = COLOR_BG_VOID
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Screen Flash Overlay (Front)
	screen_flash = ColorRect.new()
	screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.color = Color(0,0,0,0)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	# --- Header (Title and HP) ---
	var header_bar := HBoxContainer.new()
	header_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	header_bar.add_theme_constant_override("separation", 40)
	root.add_child(header_bar)
	
	hp_bar_p1 = _create_hp_bar("PLAYER 1")
	header_bar.add_child(hp_bar_p1)
	
	title_label = Label.new()
	var title_settings = LabelSettings.new()
	title_settings.font_size = 36
	title_settings.font_color = COLOR_TEXT_PRIMARY
	title_settings.outline_size = 4
	title_settings.outline_color = Color.BLACK
	title_settings.shadow_color = COLOR_FIRE
	title_settings.shadow_offset = Vector2(0, 4)
	title_label.label_settings = title_settings
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text = "POTIONS ROULETTE"
	header_bar.add_child(title_label)
	
	hp_bar_p2 = _create_hp_bar("PLAYER 2")
	header_bar.add_child(hp_bar_p2)

	# --- Center Play Area ---
	center_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_SURFACE
	panel_style.set_border_width_all(2)
	panel_style.border_color = COLOR_TEXT_MUTED
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	center_panel.add_theme_stylebox_override("panel", panel_style)
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center_panel)
	
	var play_area := VBoxContainer.new()
	play_area.alignment = BoxContainer.ALIGNMENT_CENTER
	play_area.add_theme_constant_override("separation", 30)
	center_panel.add_child(play_area)

	instructions_label = Label.new()
	var inst_settings = LabelSettings.new()
	inst_settings.font_size = 28
	inst_settings.font_color = COLOR_TEXT_PRIMARY
	instructions_label.label_settings = inst_settings
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_area.add_child(instructions_label)

	selection_label = Label.new()
	var sel_settings = LabelSettings.new()
	sel_settings.font_size = 20
	sel_settings.font_color = COLOR_TEXT_PRIMARY
	selection_label.label_settings = sel_settings
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	play_area.add_child(selection_label)

	ingredient_container = HBoxContainer.new()
	ingredient_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ingredient_container.add_theme_constant_override("separation", 16)
	play_area.add_child(ingredient_container)

	choice_container = HBoxContainer.new()
	choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_container.add_theme_constant_override("separation", 32)
	play_area.add_child(choice_container)

	# --- Action Buttons ---
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 24)
	play_area.add_child(action_row)

	primary_button = _create_styled_button("ACTION", COLOR_FIRE)
	primary_button.pressed.connect(_on_primary_button_pressed)
	action_row.add_child(primary_button)

	secondary_button = _create_styled_button("RESET", COLOR_TEXT_MUTED)
	secondary_button.pressed.connect(_on_secondary_button_pressed)
	action_row.add_child(secondary_button)

	# --- Log Area ---
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 140)
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	
	var log_panel = PanelContainer.new()
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = COLOR_BG_VOID
	log_style.set_border_width_all(1)
	log_style.border_color = COLOR_TEXT_MUTED
	log_style.content_margin_left = 16
	log_style.content_margin_top = 16
	log_style.content_margin_right = 16
	log_style.content_margin_bottom = 16
	log_panel.add_theme_stylebox_override("panel", log_style)
	log_panel.add_child(log_label)
	root.add_child(log_panel)
	
	add_child(screen_flash)

func _create_hp_bar(player_name: String) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(250, 40)
	bar.max_value = MAX_HP
	bar.value = MAX_HP
	bar.show_percentage = false
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = COLOR_BG_VOID
	bg_style.set_border_width_all(2)
	bg_style.border_color = COLOR_TEXT_MUTED
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = COLOR_TEXT_PRIMARY
	bar.add_theme_stylebox_override("fill", fill_style)
	
	var name_label = Label.new()
	name_label.text = player_name
	name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_label.position.y = -24
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ls = LabelSettings.new()
	ls.font_size = 14
	ls.font_color = COLOR_TEXT_MUTED
	name_label.label_settings = ls
	bar.add_child(name_label)
	
	var v_label = Label.new()
	v_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	v_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var vls = LabelSettings.new()
	vls.font_size = 24
	vls.font_color = Color.BLACK
	vls.outline_size = 2
	vls.outline_color = Color.WHITE
	v_label.label_settings = vls
	bar.add_child(v_label)
	
	return bar

func _update_hp_bar_visuals(bar: ProgressBar, hp: int) -> void:
	bar.value = hp
	var v_label = bar.get_child(1) as Label
	v_label.text = str(hp) + " / " + str(MAX_HP)
	
	var fill = bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		if hp > 6: fill.bg_color = COLOR_HEAL
		elif hp > 3: fill.bg_color = Color("#CCAA33") # Yellow warning
		else: fill.bg_color = COLOR_FIRE

func _create_styled_button(text: String, base_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 60)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color.darkened(0.5)
	normal.set_border_width_all(2)
	normal.border_color = base_color
	normal.corner_radius_all = 8
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = base_color.darkened(0.2)
	hover.set_border_width_all(2)
	hover.border_color = base_color.lightened(0.5)
	hover.corner_radius_all = 8
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed = hover.duplicate()
	pressed.bg_color = base_color
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var disabled = normal.duplicate()
	disabled.bg_color = COLOR_BG_VOID
	disabled.border_color = COLOR_TEXT_MUTED
	btn.add_theme_stylebox_override("disabled", disabled)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 20)
	
	return btn

func _reset_match() -> void:
	players = [
		{"name": "Player 1", "hp": MAX_HP, "pending_poison": 0},
		{"name": "Player 2", "hp": MAX_HP, "pending_poison": 0},
	]
	active_player = 0
	turn_number = 0
	phase = Phase.PASS_TO_ACTIVE
	current_ingredients = []
	selected_ingredient_indexes = []
	brewed_potions = []
	winner_text = ""
	log_lines = ["[color=#D4D4D4]The alchemy table is set.[/color]"]
	_update_hp_bar_visuals(hp_bar_p1, MAX_HP)
	_update_hp_bar_visuals(hp_bar_p2, MAX_HP)

func _on_primary_button_pressed() -> void:
	match phase:
		Phase.PASS_TO_ACTIVE: _start_turn()
		Phase.CRAFT:
			if selected_ingredient_indexes.size() == INGREDIENTS_PER_TURN:
				_lock_potions()
		Phase.PASS_TO_CHOOSER:
			phase = Phase.CHOOSE
			_animate_phase_transition()
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
	_log("[color=#9933CC]--- Turn %d : %s ---[/color]" % [turn_number, _player_name(active_player)])
	_animate_phase_transition()
	_update_ui()

func _apply_pending_poison(player_index: int) -> void:
	var poison := int(players[player_index]["pending_poison"])
	if poison <= 0: return

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
	_log("%s brewed two dark concoctions." % _player_name(active_player))
	_animate_phase_transition()
	_update_ui()

func _on_ingredient_pressed(index: int) -> void:
	if phase != Phase.CRAFT: return
	if selected_ingredient_indexes.has(index): return
	if selected_ingredient_indexes.size() >= INGREDIENTS_PER_TURN: return

	selected_ingredient_indexes.append(index)
	_update_ui()

func _on_choose_potion(index: int) -> void:
	if phase != Phase.CHOOSE: return

	var drinker := 1 - active_player
	_log("%s uncorks Potion %s..." % [_player_name(drinker), _potion_name(index)])
	_resolve_potion(index)

	if _check_for_game_over():
		_update_ui()
		return

	active_player = drinker
	phase = Phase.PASS_TO_ACTIVE
	current_ingredients = []
	selected_ingredient_indexes.clear()
	brewed_potions.clear()
	_animate_phase_transition()
	_update_ui()

func _resolve_potion(index: int) -> void:
	var brewer := active_player
	var drinker := 1 - active_player
	var potion := brewed_potions[index]
	var sorted_potion := potion.duplicate()
	sorted_potion.sort()

	var text_color = _get_ingredient_color(sorted_potion[0]).to_html()
	_log("The vial contained: [color=#%s]%s[/color] !" % [text_color, _potion_text(potion)])

	if sorted_potion == [Ingredient.FIRE, Ingredient.FIRE]:
		_deal_damage(drinker, 2, "Inferno")
	elif sorted_potion == [Ingredient.POISON, Ingredient.POISON]:
		_deal_damage(drinker, 2, "Lethal Toxin")
	elif sorted_potion == [Ingredient.FIRE, Ingredient.POISON]:
		_deal_damage(drinker, 3, "Explosive Blight")
	elif sorted_potion == [Ingredient.HEAL, Ingredient.HEAL]:
		_heal_player(drinker, 2, "Pure Essence")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.HEAL]:
		var target := rng.randi_range(0, 1)
		_heal_player(target, 1, "Chaotic Relief")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.FIRE]:
		var target := rng.randi_range(0, 1)
		_deal_damage(target, 1, "Wildfire")
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.POISON]:
		_deal_damage(drinker, 1, "Venomous Dread")
		players[drinker]["pending_poison"] += 1
		_log("[color=#44CC44]%s is afflicted with Lingering Poison![/color]" % _player_name(drinker))
	elif sorted_potion == [Ingredient.CHAOS, Ingredient.CHAOS]:
		_resolve_chaos_event(brewer, drinker)
	else:
		_log("[color=#666666]The mixture fizzles into grey sludge. Nothing happens.[/color]")

func _resolve_chaos_event(brewer: int, drinker: int) -> void:
	_flash_screen(COLOR_CHAOS)
	var roll := rng.randi_range(1, 6)
	_log("[color=#9933CC]CHAOS MANIFESTS! (Rolled %d)[/color]" % roll)

	match roll:
		1:
			var brewer_hp := int(players[brewer]["hp"])
			var drinker_hp := int(players[drinker]["hp"])
			players[brewer]["hp"] = drinker_hp
			players[drinker]["hp"] = brewer_hp
			_update_hp_bar_visuals(hp_bar_p1, players[0]["hp"])
			_update_hp_bar_visuals(hp_bar_p2, players[1]["hp"])
			_log("[color=#CC0000]SOULS SWAPPED! Life totals exchanged![/color]")
		2:
			_deal_damage(drinker, 2, "Backfire")
		3:
			_deal_damage(0, 1, "Toxic Cloud")
			_deal_damage(1, 1, "Toxic Cloud")
		4:
			_heal_player(brewer, 1, "Twisted Boon")
		5:
			_heal_player(1 - brewer, 1, "Borrowed Time")
		6:
			_heal_player(drinker, 3, "Miraculous Recovery")

func _deal_damage(player_index: int, amount: int, source: String) -> void:
	var old_hp = players[player_index]["hp"]
	var new_hp = max(0, old_hp - amount)
	players[player_index]["hp"] = new_hp
	
	_flash_screen(COLOR_FIRE)
	_spawn_floating_text(player_index, "-%d" % amount, COLOR_FIRE)
	
	if player_index == 0: _update_hp_bar_visuals(hp_bar_p1, new_hp)
	else: _update_hp_bar_visuals(hp_bar_p2, new_hp)
	
	_log("[color=#CC0000]%s suffers %d damage from %s![/color]" % [_player_name(player_index), amount, source])

func _heal_player(player_index: int, amount: int, source: String) -> void:
	var old_hp = players[player_index]["hp"]
	var new_hp = min(MAX_HP, old_hp + amount)
	var recovered = new_hp - old_hp
	players[player_index]["hp"] = new_hp
	
	if recovered > 0:
		_flash_screen(COLOR_HEAL)
		_spawn_floating_text(player_index, "+%d" % recovered, COLOR_HEAL)
		
		if player_index == 0: _update_hp_bar_visuals(hp_bar_p1, new_hp)
		else: _update_hp_bar_visuals(hp_bar_p2, new_hp)
		
		_log("[color=#33CCCC]%s recovers %d HP from %s.[/color]" % [_player_name(player_index), recovered, source])

func _spawn_floating_text(player_index: int, text: String, color: Color) -> void:
	var float_label = Label.new()
	float_label.text = text
	var ls = LabelSettings.new()
	ls.font_size = 64
	ls.font_color = color
	ls.outline_size = 6
	ls.outline_color = Color.BLACK
	float_label.label_settings = ls
	float_label.z_index = 100
	
	# Spawn near the HP bar
	var bar = hp_bar_p1 if player_index == 0 else hp_bar_p2
	float_label.position = bar.global_position + Vector2(100, -80)
	
	get_tree().root.add_child(float_label)
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(float_label, "position:y", float_label.position.y - 120, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(float_label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(float_label.queue_free)

func _flash_screen(color: Color) -> void:
	screen_flash.color = color
	screen_flash.color.a = 0.4
	var tween = get_tree().create_tween()
	tween.tween_property(screen_flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)

func _animate_phase_transition() -> void:
	center_panel.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(center_panel, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _check_for_game_over() -> bool:
	var p1_hp := int(players[0]["hp"])
	var p2_hp := int(players[1]["hp"])

	if p1_hp <= 0 and p2_hp <= 0: winner_text = "MUTUAL DESTRUCTION"
	elif p1_hp <= 0: winner_text = "PLAYER 2 SURVIVES"
	elif p2_hp <= 0: winner_text = "PLAYER 1 SURVIVES"
	else: return false

	phase = Phase.GAME_OVER
	_flash_screen(COLOR_VOID)
	_log("[color=#CC0000][b]%s[/b][/color]" % winner_text)
	return true

func _update_ui() -> void:
	selection_label.text = _selection_text()
	log_label.text = _join_strings(log_lines, "\("\n") + "\n"

	_clear_container(ingredient_container)
	_clear_container(choice_container)

	primary_button.visible = true
	secondary_button.visible = false
	primary_button.disabled = false

	var inst_color = COLOR_TEXT_PRIMARY

	match phase:
		Phase.PASS_TO_ACTIVE:
			instructions_label.text = "PASS THE VIAL TO %s\n\nClose your eyes, opponent." % _player_name(active_player).to_upper()
			primary_button.text = "I AM READY"
			inst_color = COLOR_TEXT_MUTED
		Phase.CRAFT:
			instructions_label.text = "%s:\nBREW YOUR CONCOCTION" % _player_name(active_player).to_upper()
			primary_button.text = "SEAL POTIONS"
			primary_button.disabled = selected_ingredient_indexes.size() != INGREDIENTS_PER_TURN
			secondary_button.visible = true
			inst_color = COLOR_FIRE
			_build_ingredient_buttons()
		Phase.PASS_TO_CHOOSER:
			instructions_label.text = "THE BREW IS READY\n\nPass back to %s." % _player_name(1 - active_player).to_upper()
			primary_button.text = "REVEAL CHOICES"
			inst_color = COLOR_TEXT_MUTED
		Phase.CHOOSE:
			instructions_label.text = "%s:\nCHOOSE YOUR FATE" % _player_name(1 - active_player).to_upper()
			primary_button.visible = false
			inst_color = COLOR_TEXT_PRIMARY
			_build_choice_buttons()
		Phase.GAME_OVER:
			instructions_label.text = winner_text
			primary_button.text = "PLAY AGAIN"
			inst_color = COLOR_FIRE

	var cur_set = instructions_label.label_settings
	cur_set.font_color = inst_color
	# Force label redraw
	instructions_label.label_settings = null
	instructions_label.label_settings = cur_set

func _build_ingredient_buttons() -> void:
	for index in range(current_ingredients.size()):
		var type = current_ingredients[index]
		var color = _get_ingredient_color(type)
		var btn = _create_styled_button(_ingredient_name(type), color)
		btn.custom_minimum_size = Vector2(160, 200) # Tall card-like
		
		if selected_ingredient_indexes.has(index):
			btn.text = "LOCKED"
			btn.disabled = true
			var ds = btn.get_theme_stylebox("disabled") as StyleBoxFlat
			ds.bg_color = COLOR_BG_VOID
			ds.border_color = COLOR_BG_SURFACE
		else:
			btn.pressed.connect(Callable(self, "_on_ingredient_pressed").bind(index))
		ingredient_container.add_child(btn)

func _build_choice_buttons() -> void:
	for index in range(brewed_potions.size()):
		var btn = _create_styled_button("POTION %s\n???" % _potion_name(index), COLOR_TEXT_MUTED)
		btn.custom_minimum_size = Vector2(240, 300) # Big mystery bottles
		btn.pressed.connect(Callable(self, "_on_choose_potion").bind(index))
		choice_container.add_child(btn)

func _get_ingredient_color(type: int) -> Color:
	match type:
		Ingredient.FIRE: return COLOR_FIRE
		Ingredient.POISON: return COLOR_POISON
		Ingredient.HEAL: return COLOR_HEAL
		Ingredient.CHAOS: return COLOR_CHAOS
	return COLOR_TEXT_PRIMARY

func _selection_text() -> String:
	match phase:
		Phase.CRAFT:
			var pA := _pair_preview(0, 2)
			var pB := _pair_preview(2, 4)
			return "[ A ]  %s        |        [ B ]  %s" % [pA, pB]
		Phase.PASS_TO_CHOOSER, Phase.CHOOSE:
			if brewed_potions.size() == 2:
				return "Two mysteries wait in the dark."
		Phase.GAME_OVER:
			return "The dust settles."
	return ""

func _pair_preview(start_index: int, end_index: int) -> String:
	var names := []
	for i in range(start_index, min(end_index, selected_ingredient_indexes.size())):
		names.append(_ingredient_name(current_ingredients[selected_ingredient_indexes[i]]))
	if names.is_empty(): return "..."
	return _join_strings(names, " + ")

func _ingredient_name(ingredient: int) -> String:
	match ingredient:
		Ingredient.FIRE: return "FIRE"
		Ingredient.POISON: return "POISON"
		Ingredient.HEAL: return "HEAL"
		Ingredient.CHAOS: return "CHAOS"
	return "UNKNOWN"

func _potion_name(index: int) -> String:
	return "A" if index == 0 else "B"

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
