extends Control

const MAX_HP := 10
const STARTING_DECK := [
	"fire",
	"fire",
	"fire",
	"fire",
	"poison",
	"poison",
	"poison",
	"poison",
	"heal",
	"heal",
	"heal",
	"heal",
	"heal",
	"heal",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
	"chaos",
]
const DEFAULT_POTION := ["chaos", "chaos"]
const CARD_ORDER := ["fire", "poison", "heal", "chaos"]
const RANDOM_CARD_POOL := ["fire", "poison", "heal", "chaos"]
const CARD_LABELS := {
	"fire": "Fire",
	"poison": "Poison",
	"heal": "Heal",
	"chaos": "Chaos",
}
const CARD_SCENE := preload("res://scenes/Card.tscn")
const POTION_SCENE := preload("res://scenes/Potion.tscn")
const ART_ASSETS := preload("res://scripts/art_assets.gd")
const MONSTER_PATHS := [
	"res://assets/sprites/monster/monster.png",
	"res://assets/sprites/monster/monster2.png",
]

enum Phase {
	PLAYER_BREW,
	PLAYER_CHOOSE,
	AI_CHOOSING,
	ROUND_RESULT,
	GAME_OVER,
}

var rng := RandomNumberGenerator.new()
var player_hp := MAX_HP
var ai_hp := MAX_HP
var turn_count := 1
var is_player_turn := true
var game_over := false
var player_hand: Array = []
var ai_hand: Array = []
var current_left_potion: Array = []
var current_right_potion: Array = []
var selected_hand_cards: Array = []
var player_life_lost_this_round := 0
var ai_life_lost_this_round := 0
var result_text := ""
var phase := Phase.PLAYER_BREW
var hand_card_views: Array = []
var potion_views: Array = []
var monster_anim_time := 0.0
var monster_frame_time := 0.0
var monster_frame_index := 0

var layout_margin: MarginContainer
var board_root: VBoxContainer
var header_grid: GridContainer
var potion_grid: GridContainer
var battle_row: HFlowContainer
var center_column: VBoxContainer
var title_label: Label
var turn_label: Label
var player_hp_label: Label
var ai_hp_label: Label
var player_hp_bar: ProgressBar
var ai_hp_bar: ProgressBar
var player_hp_value_label: Label
var ai_hp_value_label: Label
var player_hand_label: Label
var bot_hand_label: Label
var player_hand_grid: GridContainer
var bot_hand_grid: GridContainer
var monster_sprite: TextureRect
var choose_a_button: Button
var choose_b_button: Button
var action_button: Button
var reset_button: Button
var menu_overlay: Control
var end_overlay: Control
var end_title_label: Label
var end_message_label: Label
var notification_panel: PanelContainer
var notification_label: Label
var notification_sequence := 0
var monster_tween: Tween


func _ready() -> void:
	rng.randomize()
	_apply_app_theme()
	_apply_custom_cursors()
	_build_ui()
	set_process(true)
	resized.connect(_refresh_responsive_layout)
	_show_menu()
	_refresh_responsive_layout()


func _process(delta: float) -> void:
	if not is_instance_valid(monster_sprite):
		return

	monster_anim_time += delta
	monster_frame_time += delta

	if monster_frame_time >= 0.32:
		monster_frame_time = 0.0
		monster_frame_index = (monster_frame_index + 1) % MONSTER_PATHS.size()
		monster_sprite.texture = ART_ASSETS.get_loose_texture(MONSTER_PATHS[monster_frame_index])

	var pulse := 1.0 + sin(monster_anim_time * 3.0) * 0.04
	monster_sprite.scale = Vector2.ONE * pulse
	monster_sprite.modulate = Color(1.0, 1.0, 1.0, 0.92 + sin(monster_anim_time * 4.0) * 0.08)


func _apply_app_theme() -> void:
	var app_theme := Theme.new()
	var times_font := SystemFont.new()
	times_font.font_names = PackedStringArray(["Times New Roman"])
	app_theme.default_font = times_font
	app_theme.default_font_size = 18
	theme = app_theme


func _apply_custom_cursors() -> void:
	var tilted_cursor: Texture2D = ART_ASSETS.get_cursor_texture(false)
	var horizontal_cursor: Texture2D = ART_ASSETS.get_cursor_texture(true)

	if tilted_cursor != null:
		Input.set_custom_mouse_cursor(tilted_cursor, Input.CURSOR_ARROW, Vector2(4, 4))
	if horizontal_cursor != null:
		Input.set_custom_mouse_cursor(horizontal_cursor, Input.CURSOR_POINTING_HAND, Vector2(6, horizontal_cursor.get_height() / 2))
		Input.set_custom_mouse_cursor(horizontal_cursor, Input.CURSOR_DRAG, Vector2(6, horizontal_cursor.get_height() / 2))


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#090d14")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	layout_margin = MarginContainer.new()
	layout_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_margin.add_theme_constant_override("margin_left", 30)
	layout_margin.add_theme_constant_override("margin_top", 24)
	layout_margin.add_theme_constant_override("margin_right", 30)
	layout_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(layout_margin)

	board_root = VBoxContainer.new()
	board_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_root.add_theme_constant_override("separation", 12)
	layout_margin.add_child(board_root)

	title_label = Label.new()
	title_label.text = "Potions Roulette"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	board_root.add_child(title_label)

	header_grid = GridContainer.new()
	header_grid.columns = 3
	header_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_grid.add_theme_constant_override("h_separation", 24)
	header_grid.add_theme_constant_override("v_separation", 14)
	board_root.add_child(header_grid)

	var player_status := VBoxContainer.new()
	player_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_status.add_theme_constant_override("separation", 8)
	header_grid.add_child(player_status)

	player_hp_label = Label.new()
	player_hp_label.text = "Player HP"
	player_hp_label.add_theme_font_size_override("font_size", 24)
	player_status.add_child(player_hp_label)

	player_hp_bar = _create_hp_bar(Color("#c66050"))
	player_status.add_child(player_hp_bar)
	player_hp_value_label = player_hp_bar.get_node("ValueLabel") as Label

	turn_label = Label.new()
	turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 24)
	header_grid.add_child(turn_label)

	var bot_status := VBoxContainer.new()
	bot_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_status.add_theme_constant_override("separation", 8)
	header_grid.add_child(bot_status)

	ai_hp_label = Label.new()
	ai_hp_label.text = "Bot HP"
	ai_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_hp_label.add_theme_font_size_override("font_size", 24)
	bot_status.add_child(ai_hp_label)

	ai_hp_bar = _create_hp_bar(Color("#7a58c9"))
	bot_status.add_child(ai_hp_bar)
	ai_hp_value_label = ai_hp_bar.get_node("ValueLabel") as Label

	battle_row = HFlowContainer.new()
	battle_row.alignment = FlowContainer.ALIGNMENT_CENTER
	battle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_row.add_theme_constant_override("h_separation", 20)
	battle_row.add_theme_constant_override("v_separation", 18)
	board_root.add_child(battle_row)

	var player_hand_panel := _create_panel(Color("#0f1522"), Color("#28445f"))
	player_hand_panel.custom_minimum_size = Vector2(138, 0)
	player_hand_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	battle_row.add_child(player_hand_panel)

	var player_hand_box := VBoxContainer.new()
	player_hand_box.add_theme_constant_override("separation", 10)
	player_hand_panel.add_child(player_hand_box)

	player_hand_label = Label.new()
	player_hand_label.text = "Player Hand"
	player_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hand_label.add_theme_font_size_override("font_size", 22)
	player_hand_label.visible = false
	player_hand_box.add_child(player_hand_label)

	player_hand_grid = GridContainer.new()
	player_hand_grid.columns = 1
	player_hand_grid.add_theme_constant_override("h_separation", 8)
	player_hand_grid.add_theme_constant_override("v_separation", 10)
	player_hand_box.add_child(player_hand_grid)

	center_column = VBoxContainer.new()
	center_column.custom_minimum_size = Vector2(540, 0)
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_column.alignment = BoxContainer.ALIGNMENT_CENTER
	center_column.add_theme_constant_override("separation", 12)
	battle_row.add_child(center_column)

	var monster_stage := CenterContainer.new()
	monster_stage.custom_minimum_size = Vector2(0, 110)
	center_column.add_child(monster_stage)

	monster_sprite = TextureRect.new()
	monster_sprite.texture = ART_ASSETS.get_loose_texture(MONSTER_PATHS[0])
	monster_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster_sprite.custom_minimum_size = Vector2(128, 128)
	monster_sprite.modulate = Color(1, 1, 1, 0.95)
	monster_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	monster_stage.add_child(monster_sprite)

	var potion_stage := CenterContainer.new()
	potion_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	potion_stage.custom_minimum_size = Vector2(0, 190)
	center_column.add_child(potion_stage)

	potion_grid = GridContainer.new()
	potion_grid.columns = 2
	potion_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	potion_grid.add_theme_constant_override("h_separation", 34)
	potion_grid.add_theme_constant_override("v_separation", 18)
	potion_stage.add_child(potion_grid)

	potion_views.clear()
	for potion_name in ["Potion A", "Potion B"]:
		var potion_view := POTION_SCENE.instantiate() as PotionUI
		potion_view.custom_minimum_size = Vector2(150, 170)
		potion_view.set_title(potion_name)
		potion_view.display_cards([], false)
		potion_grid.add_child(potion_view)
		potion_views.append(potion_view)

	var choice_row := HFlowContainer.new()
	choice_row.alignment = FlowContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("h_separation", 20)
	choice_row.add_theme_constant_override("v_separation", 14)
	center_column.add_child(choice_row)

	choose_a_button = Button.new()
	choose_a_button.text = "Choose Potion A"
	choose_a_button.custom_minimum_size = Vector2(220, 48)
	choose_a_button.pressed.connect(_on_choose_potion_a)
	choice_row.add_child(choose_a_button)

	choose_b_button = Button.new()
	choose_b_button.text = "Choose Potion B"
	choose_b_button.custom_minimum_size = Vector2(220, 48)
	choose_b_button.pressed.connect(_on_choose_potion_b)
	choice_row.add_child(choose_b_button)

	var action_row := HFlowContainer.new()
	action_row.alignment = FlowContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("h_separation", 16)
	action_row.add_theme_constant_override("v_separation", 14)
	center_column.add_child(action_row)

	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(230, 50)
	action_button.pressed.connect(_on_action_button_pressed)
	action_row.add_child(action_button)

	reset_button = Button.new()
	reset_button.text = "Reset Brew"
	reset_button.custom_minimum_size = Vector2(180, 50)
	reset_button.pressed.connect(_on_reset_button_pressed)
	action_row.add_child(reset_button)

	var bot_hand_panel := _create_panel(Color("#101424"), Color("#4b3979"))
	bot_hand_panel.custom_minimum_size = Vector2(138, 0)
	bot_hand_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	battle_row.add_child(bot_hand_panel)

	var bot_hand_box := VBoxContainer.new()
	bot_hand_box.add_theme_constant_override("separation", 10)
	bot_hand_panel.add_child(bot_hand_box)

	bot_hand_label = Label.new()
	bot_hand_label.text = "Bot Hand"
	bot_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_hand_label.add_theme_font_size_override("font_size", 22)
	bot_hand_label.visible = false
	bot_hand_box.add_child(bot_hand_label)

	bot_hand_grid = GridContainer.new()
	bot_hand_grid.columns = 1
	bot_hand_grid.add_theme_constant_override("h_separation", 8)
	bot_hand_grid.add_theme_constant_override("v_separation", 10)
	bot_hand_box.add_child(bot_hand_grid)

	_build_notification_bar()
	_build_menu_overlay()
	_build_end_overlay()


func _create_panel(bg_color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_hp_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = MAX_HP
	bar.value = MAX_HP
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220, 24)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#151b27")
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.corner_radius_bottom_right = 10
	bg_style.set_border_width_all(1)
	bg_style.border_color = Color("#3d4d66")
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_left = 10
	fill_style.corner_radius_bottom_right = 10
	bar.add_theme_stylebox_override("fill", fill_style)

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", Color("#f4f0e8"))
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	value_label.add_theme_constant_override("outline_size", 3)
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(value_label)

	return bar


func _build_notification_bar() -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)

	var bottom_center := CenterContainer.new()
	bottom_center.anchor_left = 0.0
	bottom_center.anchor_top = 1.0
	bottom_center.anchor_right = 1.0
	bottom_center.anchor_bottom = 1.0
	bottom_center.offset_top = -88.0
	bottom_center.offset_bottom = -20.0
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bottom_center)

	notification_panel = _create_panel(Color(0.05, 0.08, 0.13, 0.88), Color("#41577a"))
	notification_panel.visible = false
	notification_panel.custom_minimum_size = Vector2(660, 52)
	notification_panel.modulate = Color(1, 1, 1, 0)
	notification_panel.scale = Vector2.ONE * 0.96
	bottom_center.add_child(notification_panel)

	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notification_label.add_theme_font_size_override("font_size", 20)
	notification_panel.add_child(notification_label)


func _build_menu_overlay() -> void:
	var overlay := _create_screen_overlay()
	menu_overlay = overlay["overlay"]
	var panel := overlay["panel"] as PanelContainer
	panel.custom_minimum_size = Vector2(560, 0)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Potions Roulette"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Brew two hidden potions, force the Bot to drink one, and survive the chaos."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20)
	box.add_child(subtitle)

	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 16)
	box.add_child(preview_row)

	for card_name in CARD_ORDER:
		preview_row.add_child(_create_menu_card_preview(card_name))

	var start_button := Button.new()
	start_button.text = "Start Match"
	start_button.custom_minimum_size = Vector2(220, 52)
	start_button.pressed.connect(_on_menu_start_pressed)
	box.add_child(start_button)

	var help_label := Label.new()
	help_label.text = "Left click adds a card. Right click removes one. Brew Potion A first, then Potion B."
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.add_theme_font_size_override("font_size", 17)
	help_label.modulate = Color(0.86, 0.88, 0.93, 0.85)
	box.add_child(help_label)


func _build_end_overlay() -> void:
	var overlay := _create_screen_overlay()
	end_overlay = overlay["overlay"]
	end_overlay.visible = false
	var panel := overlay["panel"] as PanelContainer
	panel.custom_minimum_size = Vector2(500, 0)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	end_title_label = Label.new()
	end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title_label.add_theme_font_size_override("font_size", 36)
	box.add_child(end_title_label)

	end_message_label = Label.new()
	end_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_message_label.add_theme_font_size_override("font_size", 20)
	box.add_child(end_message_label)

	var button_row := HFlowContainer.new()
	button_row.alignment = FlowContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("h_separation", 16)
	button_row.add_theme_constant_override("v_separation", 14)
	box.add_child(button_row)

	var play_again_button := Button.new()
	play_again_button.text = "Play Again"
	play_again_button.custom_minimum_size = Vector2(190, 50)
	play_again_button.pressed.connect(_on_play_again_pressed)
	button_row.add_child(play_again_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.custom_minimum_size = Vector2(190, 50)
	menu_button.pressed.connect(_on_back_to_menu_pressed)
	button_row.add_child(menu_button)


func _create_screen_overlay() -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.05, 0.84)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(center)

	var panel := _create_panel(Color("#101826"), Color("#485775"))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)

	return {
		"overlay": overlay,
		"panel": panel,
	}


func _create_menu_card_preview(card_name: String) -> Control:
	var frame := MarginContainer.new()
	frame.custom_minimum_size = Vector2(86, 128)

	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = ART_ASSETS.get_card_texture(_card_type_for_name(card_name))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)

	return frame


func _show_menu() -> void:
	board_root.visible = false
	menu_overlay.visible = true
	end_overlay.visible = false
	AudioManager.play_menu_music()


func _show_end_overlay() -> void:
	menu_overlay.visible = false
	end_overlay.visible = true
	AudioManager.play_sfx("result", 0.02)

	if result_text.begins_with("Result: Player wins"):
		end_title_label.text = "Victory"
	elif result_text.begins_with("Result: Bot wins"):
		end_title_label.text = "Defeat"
	else:
		end_title_label.text = "Draw"

	end_message_label.text = result_text


func _on_menu_start_pressed() -> void:
	AudioManager.play_sfx("ui", 0.02)
	menu_overlay.visible = false
	end_overlay.visible = false
	board_root.visible = true
	AudioManager.play_game_music()
	_start_match()


func _on_play_again_pressed() -> void:
	AudioManager.play_sfx("ui", 0.02)
	end_overlay.visible = false
	board_root.visible = true
	AudioManager.play_game_music()
	_start_match()


func _on_back_to_menu_pressed() -> void:
	AudioManager.play_sfx("ui", 0.02)
	_show_menu()


func _refresh_responsive_layout() -> void:
	if not is_instance_valid(player_hand_grid):
		return

	var board_width := size.x
	var narrow := board_width < 1180.0
	var compact := board_width < 940.0

	layout_margin.add_theme_constant_override("margin_left", 18 if narrow else 30)
	layout_margin.add_theme_constant_override("margin_top", 18 if narrow else 24)
	layout_margin.add_theme_constant_override("margin_right", 18 if narrow else 30)
	layout_margin.add_theme_constant_override("margin_bottom", 18 if narrow else 24)

	header_grid.columns = 1 if compact else 3
	potion_grid.columns = 1 if compact else 2
	center_column.custom_minimum_size = Vector2(420, 0) if compact else Vector2(540, 0)
	battle_row.add_theme_constant_override("h_separation", 14 if compact else 20)
	battle_row.add_theme_constant_override("v_separation", 14 if compact else 18)

	title_label.add_theme_font_size_override("font_size", 30 if narrow else 38)
	turn_label.add_theme_font_size_override("font_size", 20 if narrow else 24)
	player_hand_label.add_theme_font_size_override("font_size", 19 if narrow else 22)
	bot_hand_label.add_theme_font_size_override("font_size", 19 if narrow else 22)
	monster_sprite.custom_minimum_size = Vector2(100, 100) if compact else Vector2(128, 128)
	notification_panel.custom_minimum_size = Vector2(420 if compact else 660, 50)
	notification_label.add_theme_font_size_override("font_size", 18 if compact else 20)

	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
	ai_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_RIGHT

	for potion_view in potion_views:
		potion_view.custom_minimum_size = Vector2(120, 146) if compact else Vector2(144, 164)


func _start_match() -> void:
	player_hp = MAX_HP
	ai_hp = MAX_HP
	turn_count = 1
	is_player_turn = true
	game_over = false
	result_text = ""
	player_hand = _build_starting_deck()
	ai_hand = _build_starting_deck()
	_sort_hand(player_hand)
	_sort_hand(ai_hand)
	current_left_potion.clear()
	current_right_potion.clear()
	selected_hand_cards.clear()
	end_overlay.visible = false
	notification_sequence += 1
	notification_panel.visible = false
	_start_turn()


func _build_starting_deck() -> Array:
	return STARTING_DECK.duplicate()


func _start_turn() -> void:
	player_life_lost_this_round = 0
	ai_life_lost_this_round = 0
	current_left_potion.clear()
	current_right_potion.clear()
	selected_hand_cards.clear()
	result_text = ""

	if is_player_turn:
		phase = Phase.PLAYER_BREW
		_sync_player_brew_preview()
	else:
		var ai_notice := _craft_ai_potions()
		phase = Phase.PLAYER_CHOOSE
		_show_potions(current_left_potion, current_right_potion, false)
		var lines: Array = []
		if not ai_notice.is_empty():
			lines.append(ai_notice)
		lines.append("Bot brewed two hidden potions. Choose one to drink.")
		_set_summary_text(_join_lines(lines))
		_update_ui()


func _notice_prefix(text: String) -> String:
	if text.is_empty():
		return ""
	return text + "\n"


func _set_summary_text(text: String) -> void:
	_queue_notification_lines(text.split("\n"))


func _render_player_hand() -> void:
	for child in player_hand_grid.get_children():
		child.queue_free()
	for child in bot_hand_grid.get_children():
		child.queue_free()
	hand_card_views.clear()

	var player_counts := _count_cards(player_hand)
	var selected_counts := _count_cards(selected_hand_cards)
	var bot_counts := _count_cards(ai_hand)

	for card_name in CARD_ORDER:
		var available_count := int(player_counts.get(card_name, 0))
		if available_count > 0:
			var player_card := _create_hand_card(
				card_name,
				available_count,
				int(selected_counts.get(card_name, 0)),
				phase == Phase.PLAYER_BREW
			)
			player_hand_grid.add_child(player_card)
			player_card.play_spawn_animation(true)
			hand_card_views.append(player_card)

		var bot_count := int(bot_counts.get(card_name, 0))
		if bot_count > 0:
			var bot_card := _create_hand_card(card_name, bot_count, 0, false)
			bot_hand_grid.add_child(bot_card)
			bot_card.play_spawn_animation(false)


func _create_hand_card(card_name: String, count: int, selected: int, clickable: bool) -> CardUI:
	var card_view := CARD_SCENE.instantiate() as CardUI
	card_view.custom_minimum_size = Vector2(90, 132)
	card_view.setup(CardData.new(_card_type_for_name(card_name)))
	card_view.set_card_key(card_name)
	card_view.set_count(count)
	card_view.set_selected(selected > 0)
	card_view.set_selected_count(selected)
	card_view.set_clickable(clickable)
	if clickable:
		card_view.card_selected.connect(_on_player_card_selected)
		card_view.card_removed.connect(_on_player_card_removed)
	return card_view


func _on_player_card_selected(card_view: CardUI) -> void:
	if phase != Phase.PLAYER_BREW:
		return

	if selected_hand_cards.size() >= _required_player_selection_count():
		return

	if _remaining_count_for_card(card_view.card_key) <= 0:
		return

	selected_hand_cards.append(card_view.card_key)
	AudioManager.play_sfx("card_add", 0.03)
	card_view.play_pulse_animation()
	_sync_player_brew_preview()


func _on_player_card_removed(card_view: CardUI) -> void:
	if phase != Phase.PLAYER_BREW:
		return

	if not _remove_selected_card(card_view.card_key):
		return

	AudioManager.play_sfx("card_remove", 0.02)
	card_view.play_pulse_animation()
	_sync_player_brew_preview()


func _remaining_count_for_card(card_name: String) -> int:
	return _count_card(player_hand, card_name) - _count_card(selected_hand_cards, card_name)


func _required_player_selection_count() -> int:
	var usable_cards: int = mini(4, player_hand.size())
	if usable_cards % 2 == 1:
		usable_cards -= 1
	return usable_cards


func _sync_player_brew_preview() -> void:
	var preview := _build_player_preview_potions()
	current_left_potion = preview["left"]
	current_right_potion = preview["right"]
	_show_potions(current_left_potion, current_right_potion, true)
	_set_summary_text(_brew_instruction_text())
	_update_ui()


func _build_player_preview_potions() -> Dictionary:
	var required := _required_player_selection_count()
	var left: Array = []
	var right: Array = []

	if required == 0:
		left = DEFAULT_POTION.duplicate()
		right = DEFAULT_POTION.duplicate()
		return {"left": left, "right": right}

	for index in range(min(2, selected_hand_cards.size())):
		left.append(selected_hand_cards[index])

	if required == 2:
		right = DEFAULT_POTION.duplicate()
		return {"left": left, "right": right}

	for index in range(2, min(4, selected_hand_cards.size())):
		right.append(selected_hand_cards[index])

	return {"left": left, "right": right}


func _brew_instruction_text() -> String:
	var required := _required_player_selection_count()
	var selected := selected_hand_cards.size()

	if required == 0:
		return "No cards to brew. Both potions default to Chaos + Chaos."

	if required == 2:
		if selected < 2:
			return "Choose 2 cards for Potion A. Potion B defaults to Chaos + Chaos."
		return "Potion A is ready. Confirm to let the Bot choose."

	match selected:
		0:
			return "Choose 2 cards for Potion A."
		1:
			return "Potion A needs 1 more card."
		2:
			return "Potion A is ready. Choose 2 cards for Potion B."
		3:
			return "Potion B needs 1 more card."
		4:
			return "Both potions are ready. Confirm to let the Bot choose."
	return "Player is brewing."


func _on_choose_potion_a() -> void:
	if phase == Phase.PLAYER_CHOOSE:
		AudioManager.play_sfx("confirm", 0.02)
		_resolve_turn(0)


func _on_choose_potion_b() -> void:
	if phase == Phase.PLAYER_CHOOSE:
		AudioManager.play_sfx("confirm", 0.02)
		_resolve_turn(1)


func _on_action_button_pressed() -> void:
	match phase:
		Phase.PLAYER_BREW:
			if selected_hand_cards.size() == _required_player_selection_count():
				AudioManager.play_sfx("confirm", 0.02)
				_confirm_player_brew()
		Phase.ROUND_RESULT:
			AudioManager.play_sfx("ui", 0.02)
			is_player_turn = not is_player_turn
			turn_count += 1
			_start_turn()


func _on_reset_button_pressed() -> void:
	if phase != Phase.PLAYER_BREW:
		return
	AudioManager.play_sfx("card_remove", 0.02)
	selected_hand_cards.clear()
	_sync_player_brew_preview()


func _confirm_player_brew() -> void:
	var required := _required_player_selection_count()

	if required == 0:
		current_left_potion = DEFAULT_POTION.duplicate()
		current_right_potion = DEFAULT_POTION.duplicate()
	elif required == 2:
		current_left_potion = [
			selected_hand_cards[0],
			selected_hand_cards[1],
		]
		current_right_potion = DEFAULT_POTION.duplicate()
	else:
		current_left_potion = [
			selected_hand_cards[0],
			selected_hand_cards[1],
		]
		current_right_potion = [
			selected_hand_cards[2],
			selected_hand_cards[3],
		]

	for card_name in selected_hand_cards:
		var remove_index: int = player_hand.find(card_name)
		if remove_index != -1:
			player_hand.remove_at(remove_index)

	selected_hand_cards.clear()
	phase = Phase.AI_CHOOSING
	_show_potions(current_left_potion, current_right_potion, true)
	_set_summary_text("You slid two hidden potions to the Bot.\nBot is choosing now.")
	_update_ui()
	call_deferred("_run_ai_choice")


func _run_ai_choice() -> void:
	await get_tree().create_timer(0.9).timeout
	if phase != Phase.AI_CHOOSING:
		return
	_resolve_turn(rng.randi_range(0, 1))


func _craft_ai_potions() -> String:
	if ai_hand.size() < 2:
		current_left_potion = DEFAULT_POTION.duplicate()
		current_right_potion = DEFAULT_POTION.duplicate()
		return "Bot cannot build either potion, so both default to Chaos + Chaos."

	if ai_hand.size() < 4:
		var real_potion := _craft_ai_single_potion()
		var default_potion := DEFAULT_POTION.duplicate()
		if rng.randi_range(0, 1) == 0:
			current_left_potion = real_potion
			current_right_potion = default_potion
		else:
			current_left_potion = default_potion
			current_right_potion = real_potion
		return "Bot cannot build both potions, so one defaults to Chaos + Chaos."

	var plans := _iter_craft_plans(ai_hand)
	var best_score := -INF
	var best_plans: Array = []

	for plan in plans:
		var score := _score_ai_craft_plan(plan)
		if score > best_score:
			best_score = score
			best_plans = [plan]
		elif score == best_score:
			best_plans.append(plan)

	var chosen_plan: Dictionary = best_plans[rng.randi_range(0, best_plans.size() - 1)]
	for index in _sorted_descending(chosen_plan["used_indices"]):
		ai_hand.remove_at(index)

	if rng.randi_range(0, 1) == 0:
		current_left_potion = chosen_plan["potion_a"].duplicate()
		current_right_potion = chosen_plan["potion_b"].duplicate()
	else:
		current_left_potion = chosen_plan["potion_b"].duplicate()
		current_right_potion = chosen_plan["potion_a"].duplicate()

	return ""


func _craft_ai_single_potion() -> Array:
	var scored_pairs: Array = []
	var default_potion := DEFAULT_POTION.duplicate()

	for a in range(ai_hand.size() - 1):
		for b in range(a + 1, ai_hand.size()):
			var potion := [ai_hand[a], ai_hand[b]]
			var score := _score_ai_hidden_pair(potion, default_potion)
			scored_pairs.append({"score": score, "indices": [a, b]})

	var best_score := -INF
	var best_pairs: Array = []
	for entry in scored_pairs:
		if entry["score"] > best_score:
			best_score = entry["score"]
			best_pairs = [entry]
		elif entry["score"] == best_score:
			best_pairs.append(entry)

	var chosen_pair: Dictionary = best_pairs[rng.randi_range(0, best_pairs.size() - 1)]
	var potion := [ai_hand[chosen_pair["indices"][0]], ai_hand[chosen_pair["indices"][1]]]
	for index in _sorted_descending(chosen_pair["indices"]):
		ai_hand.remove_at(index)
	return potion


func _iter_craft_plans(hand: Array) -> Array:
	var plans: Array = []
	var seen := {}

	for a in range(hand.size() - 3):
		for b in range(a + 1, hand.size() - 2):
			for c in range(b + 1, hand.size() - 1):
				for d in range(c + 1, hand.size()):
					var used_indices := [a, b, c, d]
					var cards := [hand[a], hand[b], hand[c], hand[d]]
					var pairings := [
						[[cards[0], cards[1]], [cards[2], cards[3]]],
						[[cards[0], cards[2]], [cards[1], cards[3]]],
						[[cards[0], cards[3]], [cards[1], cards[2]]],
					]

					for pairing in pairings:
						var plan_key := "%s|%s|%s" % [
							_sorted_potion_key(pairing[0]),
							_sorted_potion_key(pairing[1]),
							str(used_indices),
						]
						if seen.has(plan_key):
							continue
						seen[plan_key] = true
						plans.append({
							"used_indices": used_indices.duplicate(),
							"potion_a": pairing[0].duplicate(),
							"potion_b": pairing[1].duplicate(),
						})

	return plans


func _sorted_potion_key(cards: Array) -> String:
	var sorted_cards := cards.duplicate()
	sorted_cards.sort()
	return "%s,%s" % [sorted_cards[0], sorted_cards[1]]


func _score_ai_craft_plan(plan: Dictionary) -> float:
	return _score_ai_hidden_pair(plan["potion_a"], plan["potion_b"])


func _score_ai_hidden_pair(potion_a: Array, potion_b: Array) -> float:
	var potion_a_score := _score_result_for_ai(_evaluate_potion(potion_a[0], potion_a[1]), true)
	var potion_b_score := _score_result_for_ai(_evaluate_potion(potion_b[0], potion_b[1]), false)
	var choice_a := potion_a_score + potion_b_score

	var potion_b_player_score := _score_result_for_ai(_evaluate_potion(potion_b[0], potion_b[1]), true)
	var potion_a_self_score := _score_result_for_ai(_evaluate_potion(potion_a[0], potion_a[1]), false)
	var choice_b := potion_b_player_score + potion_a_self_score

	return min(choice_a, choice_b) * 10.0 + choice_a + choice_b


func _score_result_for_ai(result: Dictionary, target_is_player: bool) -> int:
	if result["kind"] == "damage":
		return int(result["amount"]) if target_is_player else -int(result["amount"])
	if result["kind"] == "heal":
		return -int(result["amount"]) if target_is_player else int(result["amount"])
	return 0


func _resolve_turn(chosen_index: int) -> void:
	var chosen_label := "Potion A" if chosen_index == 0 else "Potion B"
	var other_label := "Potion B" if chosen_index == 0 else "Potion A"
	var chosen_potion: Array = current_left_potion if chosen_index == 0 else current_right_potion
	var other_potion: Array = current_right_potion if chosen_index == 0 else current_left_potion
	var chooser_is_player := not is_player_turn
	var chooser_label := "Player" if chooser_is_player else "Bot"
	var brewer_label := "Player" if is_player_turn else "Bot"
	var brewer_hand: Array = player_hand if is_player_turn else ai_hand

	var lines := [
		"%s drinks %s." % [chooser_label, chosen_label],
		"Potion A: %s | Potion B: %s" % [_format_potion(current_left_potion), _format_potion(current_right_potion)],
		"%s returns to %s." % [other_label, brewer_label],
	]

	lines.append_array(_apply_potion_to_target(chosen_potion, chooser_is_player, chosen_label))
	lines.append_array(_apply_potion_to_target(other_potion, is_player_turn, other_label))

	_clamp_health()

	if not _handle_simultaneous_death(brewer_hand, brewer_label, lines):
		var gained_cards := _grant_random_cards(brewer_hand, 2)
		lines.append("%s regains 2 random cards: %s" % [brewer_label, _format_card_list(gained_cards)])

	_check_game_over()
	if game_over and not result_text.is_empty():
		lines.append(result_text)

	_show_potions(current_left_potion, current_right_potion, true)
	_set_summary_text(_join_lines(lines))
	phase = Phase.GAME_OVER if game_over else Phase.ROUND_RESULT
	AudioManager.play_sfx("resolve", 0.02)
	_animate_monster_reaction()
	_update_ui()
	if game_over:
		_show_end_overlay()


func _apply_potion_to_target(potion: Array, target_is_player: bool, potion_label: String) -> Array:
	var target_label := "Player" if target_is_player else "Bot"
	var result := _evaluate_potion(potion[0], potion[1])
	var lines := ["  %s goes to %s: %s" % [potion_label, target_label, _format_potion(potion)]]
	lines.append_array(_apply_result(result, target_is_player))
	return lines


func _evaluate_potion(card1: String, card2: String) -> Dictionary:
	var cards := [card1, card2]
	cards.sort()

	if cards == ["fire", "fire"]:
		return {"kind": "damage", "label": "Fire + Fire", "amount": 2}
	if cards == ["poison", "poison"]:
		return {"kind": "damage", "label": "Poison + Poison", "amount": 2}
	if cards == ["fire", "poison"]:
		return {"kind": "damage", "label": "Fire + Poison", "amount": 3}
	if cards == ["heal", "heal"]:
		return {"kind": "heal", "label": "Heal + Heal", "amount": 2}
	if cards == ["chaos", "heal"]:
		return {"kind": "random_heal", "label": "Heal + Chaos", "amount": 1}
	if cards == ["chaos", "fire"]:
		return {"kind": "random_damage", "label": "Fire + Chaos", "amount": 1}
	if cards == ["chaos", "poison"]:
		return {"kind": "nothing", "label": "Poison + Chaos", "amount": 0}
	if cards == ["chaos", "chaos"]:
		return {"kind": "chaos_chaos", "label": "Chaos + Chaos", "amount": 0}
	return {"kind": "nothing", "label": "%s + %s" % [CARD_LABELS[cards[0]], CARD_LABELS[cards[1]]], "amount": 0}


func _apply_result(result: Dictionary, target_is_player: bool) -> Array:
	var target_label := "Player" if target_is_player else "Bot"
	var amount := int(result["amount"])
	var label := str(result["label"])

	if result["kind"] == "damage":
		var lost_amount := _deal_damage(target_is_player, amount)
		return ["    %s takes %d damage from %s." % [target_label, lost_amount, label]]

	if result["kind"] == "heal":
		var healed_amount := _heal_target(target_is_player, amount)
		return ["    %s heals %d from %s." % [target_label, healed_amount, label]]

	if result["kind"] == "random_heal":
		var heal_player := rng.randi_range(0, 1) == 0
		var healed_random := _heal_target(heal_player, amount)
		if heal_player:
			return ["    Random heal from %s goes to Player for %d." % [label, healed_random]]
		return ["    Random heal from %s goes to Bot for %d." % [label, healed_random]]

	if result["kind"] == "random_damage":
		var damage_player := rng.randi_range(0, 1) == 0
		var lost_random := _deal_damage(damage_player, amount)
		if damage_player:
			return ["    Random damage from %s hits Player for %d." % [label, lost_random]]
		return ["    Random damage from %s hits Bot for %d." % [label, lost_random]]

	if result["kind"] == "chaos_chaos":
		return _apply_chaos_chaos()

	return ["    %s has no effect." % label]


func _apply_chaos_chaos() -> Array:
	var random_target_is_player := rng.randi_range(0, 1) == 0
	var random_effect := rng.randi_range(0, 3)
	var target_label := "Player" if random_target_is_player else "Bot"

	if random_effect == 0:
		var lost_one := _deal_damage(random_target_is_player, 1)
		return ["    Chaos + Chaos damages %s by %d." % [target_label, lost_one]]

	if random_effect == 1:
		var healed_one := _heal_target(random_target_is_player, 1)
		return ["    Chaos + Chaos heals %s by %d." % [target_label, healed_one]]

	if random_effect == 2:
		var lost_two := _deal_damage(random_target_is_player, 2)
		return ["    Chaos + Chaos slams %s for %d damage." % [target_label, lost_two]]

	return ["    Chaos + Chaos sparkles and does nothing."]


func _deal_damage(target_is_player: bool, amount: int) -> int:
	if target_is_player:
		var lost_amount: int = mini(amount, player_hp)
		player_hp -= lost_amount
		player_life_lost_this_round += lost_amount
		return lost_amount

	var lost_ai: int = mini(amount, ai_hp)
	ai_hp -= lost_ai
	ai_life_lost_this_round += lost_ai
	return lost_ai


func _heal_target(target_is_player: bool, amount: int) -> int:
	if target_is_player:
		var healed_amount: int = mini(amount, MAX_HP - player_hp)
		player_hp += healed_amount
		return healed_amount

	var healed_ai: int = mini(amount, MAX_HP - ai_hp)
	ai_hp += healed_ai
	return healed_ai


func _grant_random_cards(hand: Array, amount: int) -> Array:
	var gained_cards: Array = []
	for _i in range(amount):
		var card: String = RANDOM_CARD_POOL[rng.randi_range(0, RANDOM_CARD_POOL.size() - 1)]
		hand.append(card)
		gained_cards.append(card)
	_sort_hand(hand)
	return gained_cards


func _handle_simultaneous_death(brewer_hand: Array, brewer: String, lines: Array) -> bool:
	if player_hp > 0 or ai_hp > 0:
		return false

	player_hp = mini(MAX_HP, player_hp + player_life_lost_this_round)
	ai_hp = mini(MAX_HP, ai_hp + ai_life_lost_this_round)
	lines.append("Both players were knocked out in the same round.")
	lines.append("Player regains %d life from the round." % player_life_lost_this_round)
	lines.append("Bot regains %d life from the round." % ai_life_lost_this_round)
	var gained_cards := _grant_random_cards(brewer_hand, 2)
	lines.append("%s regains 2 random cards: %s" % [brewer, _format_card_list(gained_cards)])
	return true


func _clamp_health() -> void:
	player_hp = clampi(player_hp, 0, MAX_HP)
	ai_hp = clampi(ai_hp, 0, MAX_HP)


func _check_game_over() -> void:
	if player_hp <= 0 and ai_hp <= 0:
		game_over = true
		result_text = "Result: Draw"
		return
	if player_hp <= 0:
		game_over = true
		result_text = "Result: Bot wins"
		return
	if ai_hp <= 0:
		game_over = true
		result_text = "Result: Player wins"
		return
	if player_hand.is_empty() and ai_hand.is_empty():
		game_over = true
		result_text = "Result: Draw. Both players ran out of cards."
		return
	if player_hand.is_empty():
		game_over = true
		result_text = "Result: Bot wins. Player has no cards left."
		return
	if ai_hand.is_empty():
		game_over = true
		result_text = "Result: Player wins. Bot has no cards left."
		return

	game_over = false
	result_text = ""


func _show_potions(left_cards: Array, right_cards: Array, reveal: bool) -> void:
	potion_views[0].set_title("Potion A")
	potion_views[1].set_title("Potion B")
	potion_views[0].display_cards(_card_names_to_types(left_cards), reveal)
	potion_views[1].display_cards(_card_names_to_types(right_cards), reveal)
	for potion_view in potion_views:
		potion_view.play_bounce()


func _card_names_to_types(cards: Array) -> Array:
	var result: Array = []
	for card in cards:
		result.append(_card_type_for_name(str(card)))
	return result


func _card_type_for_name(card_name: String) -> int:
	match card_name:
		"fire":
			return GameRules.CardType.FIRE
		"poison":
			return GameRules.CardType.POISON
		"heal":
			return GameRules.CardType.HEAL
		"chaos":
			return GameRules.CardType.CHAOS
	return GameRules.CardType.CHAOS


func _format_potion(potion: Array) -> String:
	if potion.is_empty():
		return "Hidden"

	var parts: Array[String] = []
	for card in potion:
		parts.append(CARD_LABELS[str(card)])
	return " + ".join(parts)


func _count_cards(cards: Array) -> Dictionary:
	var counts := {}
	for card in cards:
		counts[card] = int(counts.get(card, 0)) + 1
	return counts


func _count_card(cards: Array, card_name: String) -> int:
	return int(_count_cards(cards).get(card_name, 0))


func _remove_selected_card(card_name: String) -> bool:
	var index := selected_hand_cards.rfind(card_name)
	if index == -1:
		return false
	selected_hand_cards.remove_at(index)
	return true


func _format_card_counts(cards: Array) -> String:
	if cards.is_empty():
		return "None"

	var counts := _count_cards(cards)

	var parts: Array[String] = []
	for card in CARD_ORDER:
		if counts.get(card, 0) > 0:
			parts.append("%s x%d" % [CARD_LABELS[card], int(counts[card])])
	return ", ".join(parts)


func _format_card_list(cards: Array) -> String:
	var parts: Array[String] = []
	for card in cards:
		parts.append(CARD_LABELS[str(card)])
	return ", ".join(parts)


func _update_ui() -> void:
	player_hp_label.text = "Player HP"
	ai_hp_label.text = "Bot HP"
	player_hp_bar.value = player_hp
	ai_hp_bar.value = ai_hp
	player_hp_value_label.text = "%d / %d" % [player_hp, MAX_HP]
	ai_hp_value_label.text = "%d / %d" % [ai_hp, MAX_HP]
	turn_label.text = "Turn %d: %s brews" % [turn_count, _brewer_name()]

	choose_a_button.visible = phase == Phase.PLAYER_CHOOSE
	choose_b_button.visible = phase == Phase.PLAYER_CHOOSE
	choose_a_button.disabled = phase != Phase.PLAYER_CHOOSE
	choose_b_button.disabled = phase != Phase.PLAYER_CHOOSE

	action_button.visible = phase != Phase.PLAYER_CHOOSE and phase != Phase.GAME_OVER
	action_button.disabled = false
	reset_button.visible = phase == Phase.PLAYER_BREW
	reset_button.disabled = selected_hand_cards.is_empty()

	match phase:
		Phase.PLAYER_BREW:
			var required := _required_player_selection_count()
			if required == 0:
				action_button.text = "Confirm Default Potions"
			else:
				action_button.text = "Confirm Brew"
			action_button.disabled = selected_hand_cards.size() != required
		Phase.AI_CHOOSING:
			action_button.text = "Bot Is Choosing..."
			action_button.disabled = true
		Phase.ROUND_RESULT:
			action_button.text = "Next Turn"
		Phase.GAME_OVER:
			action_button.text = "New Match"

	_render_player_hand()


func _queue_notification_lines(lines: Array) -> void:
	var cleaned: Array[String] = []
	for line in lines:
		var text := str(line).strip_edges()
		if text.is_empty():
			continue
		if text.begins_with("Bot cards:"):
			continue
		cleaned.append(text)

	if cleaned.is_empty():
		return

	notification_sequence += 1
	call_deferred("_play_notification_sequence", cleaned, notification_sequence)


func _play_notification_sequence(lines: Array[String], sequence_id: int) -> void:
	for line in lines:
		if sequence_id != notification_sequence:
			return
		_show_notification(line)
		await get_tree().create_timer(2.0).timeout

	if sequence_id == notification_sequence:
		_hide_notification()


func _show_notification(text: String) -> void:
	notification_label.text = text
	notification_panel.visible = true
	if notification_panel.get_meta("tween", null) != null:
		var old_tween := notification_panel.get_meta("tween") as Tween
		old_tween.kill()
	notification_panel.scale = Vector2.ONE * 0.96
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(notification_panel, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.parallel().tween_property(notification_panel, "scale", Vector2.ONE, 0.18)
	notification_panel.set_meta("tween", tween)


func _hide_notification() -> void:
	if not notification_panel.visible:
		return
	if notification_panel.get_meta("tween", null) != null:
		var old_tween := notification_panel.get_meta("tween") as Tween
		old_tween.kill()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(notification_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	tween.parallel().tween_property(notification_panel, "scale", Vector2.ONE * 0.96, 0.18)
	tween.finished.connect(func() -> void:
		notification_panel.visible = false
	)
	notification_panel.set_meta("tween", tween)


func _animate_monster_reaction() -> void:
	if monster_tween != null:
		monster_tween.kill()
	monster_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	monster_tween.parallel().tween_property(monster_sprite, "scale", Vector2.ONE * 1.18, 0.14)
	monster_tween.parallel().tween_property(monster_sprite, "rotation_degrees", -6.0, 0.08)
	monster_tween.tween_property(monster_sprite, "rotation_degrees", 4.0, 0.08)
	monster_tween.tween_property(monster_sprite, "scale", Vector2.ONE, 0.16)
	monster_tween.parallel().tween_property(monster_sprite, "rotation_degrees", 0.0, 0.16)


func _brewer_name() -> String:
	return "Player" if is_player_turn else "Bot"


func _join_lines(lines: Array) -> String:
	var parts: Array[String] = []
	for line in lines:
		parts.append(str(line))
	return "\n".join(parts)


func _sorted_descending(indices: Array) -> Array:
	var copy := indices.duplicate()
	copy.sort()
	copy.reverse()
	return copy


func _sort_hand(hand: Array) -> void:
	hand.sort_custom(_compare_card_names)


func _compare_card_names(a: Variant, b: Variant) -> bool:
	var a_name := str(a)
	var b_name := str(b)
	var a_index := CARD_ORDER.find(a_name)
	var b_index := CARD_ORDER.find(b_name)

	if a_index == -1:
		a_index = CARD_ORDER.size()
	if b_index == -1:
		b_index = CARD_ORDER.size()

	if a_index == b_index:
		return a_name < b_name

	return a_index < b_index
