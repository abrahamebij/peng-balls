extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var open_bets_button = get_node_or_null("VBoxContainer/OpenBetsButton")
@onready var how_to_play_button = get_node_or_null("VBoxContainer/HowToPlayButton")
@onready var credits_button = get_node_or_null("VBoxContainer/CreditsButton")
@onready var account_info_button = get_node_or_null("AccountInfo")


func _ready():
	# Enforce authentication: no unauthenticated user should access the menu or game
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return

	start_button.pressed.connect(_on_start)
	if open_bets_button:
		open_bets_button.pressed.connect(_on_open_bets)
	if how_to_play_button:
		how_to_play_button.pressed.connect(_on_how_to_play)
	if credits_button:
		credits_button.pressed.connect(_on_credits)
	if account_info_button:
		account_info_button.pressed.connect(_on_account_info)


func _on_start():
	_show_mode_selection_modal()


func _launch_game():
	if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
		if has_node("/root/GlobalState"):
			get_node("/root/GlobalState").next_scene_path = "res://scenes/game/Game.tscn"
		get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _show_mode_selection_modal():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 380)
	panel.set_anchors_preset(Control.PRESET_CENTER)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.94, 0.88, 0.98)
	style.border_color = Color(0.24, 0.28, 0.28, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var font_bold = load("res://resources/fonts/Poppins-Bold.ttf")
	var btn_normal = load("res://styles/menu-btn.tres")
	var btn_pressed = load("res://styles/menu-btn-pressed.tres")
	var btn_hover = load("res://styles/menu-btn-hovered.tres")

	# Header
	var title = Label.new()
	title.text = "SELECT GAME MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.14, 0.18, 0.18, 1.0))
	if font_bold:
		title.add_theme_font_override("font", font_bold)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Choose whether to play for fun (free) or stake into the weekly prize pool."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
	vbox.add_child(subtitle)

	# --- Mode 1: Casual / Free ---
	var casual_card = PanelContainer.new()
	var casual_style = StyleBoxFlat.new()
	casual_style.bg_color = Color(0.88, 0.94, 0.92, 0.90)
	casual_style.border_color = Color(0.20, 0.55, 0.45, 1.0)
	casual_style.set_border_width_all(2)
	casual_style.set_corner_radius_all(8)
	casual_style.content_margin_left = 16.0
	casual_style.content_margin_right = 16.0
	casual_style.content_margin_top = 10.0
	casual_style.content_margin_bottom = 10.0
	casual_card.add_theme_stylebox_override("panel", casual_style)
	vbox.add_child(casual_card)

	var casual_hbox = HBoxContainer.new()
	casual_card.add_child(casual_hbox)

	var casual_info = VBoxContainer.new()
	casual_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	casual_hbox.add_child(casual_info)

	var casual_title = Label.new()
	casual_title.text = "🎮 Play For Fun (Casual Run)"
	casual_title.add_theme_font_size_override("font_size", 16)
	casual_title.add_theme_color_override("font_color", Color(0.10, 0.35, 0.25, 1.0))
	if font_bold:
		casual_title.add_theme_font_override("font", font_bold)
	casual_info.add_child(casual_title)

	var casual_desc = Label.new()
	casual_desc.text = "Stake: 0 SOL (Free) • Practice marble physics without staking"
	casual_desc.add_theme_font_size_override("font_size", 12)
	casual_desc.add_theme_color_override("font_color", Color(0.25, 0.45, 0.35, 1.0))
	casual_info.add_child(casual_desc)

	var casual_btn = Button.new()
	casual_btn.text = "Play Free"
	casual_btn.custom_minimum_size = Vector2(130, 36)
	_style_button(casual_btn, btn_normal, btn_pressed, btn_hover, font_bold)
	casual_btn.pressed.connect(func():
		overlay.queue_free()
		if has_node("/root/GlobalState"):
			var gs = get_node("/root/GlobalState")
			gs.active_run_mode = "casual"
			gs.active_run_pool = {}
		_launch_game()
	)
	casual_hbox.add_child(casual_btn)

	# --- Mode 2: Staked Tournament ---
	var staked_card = PanelContainer.new()
	var staked_style = StyleBoxFlat.new()
	staked_style.bg_color = Color(0.98, 0.93, 0.85, 0.90)
	staked_style.border_color = Color(0.85, 0.55, 0.10, 1.0)
	staked_style.set_border_width_all(2)
	staked_style.set_corner_radius_all(8)
	staked_style.content_margin_left = 16.0
	staked_style.content_margin_right = 16.0
	staked_style.content_margin_top = 10.0
	staked_style.content_margin_bottom = 10.0
	staked_card.add_theme_stylebox_override("panel", staked_style)
	vbox.add_child(staked_card)

	var staked_vbox = VBoxContainer.new()
	staked_vbox.add_theme_constant_override("separation", 8)
	staked_card.add_child(staked_vbox)

	var staked_title_row = HBoxContainer.new()
	staked_vbox.add_child(staked_title_row)

	var staked_info = VBoxContainer.new()
	staked_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staked_title_row.add_child(staked_info)

	var staked_title = Label.new()
	staked_title.text = "🏆 Compete in Weekly Community Pool"
	staked_title.add_theme_font_size_override("font_size", 16)
	staked_title.add_theme_color_override("font_color", Color(0.55, 0.35, 0.05, 1.0))
	if font_bold:
		staked_title.add_theme_font_override("font", font_bold)
	staked_info.add_child(staked_title)

	var staked_desc = Label.new()
	staked_desc.text = "Stake to enter the community pot • 90% prize to 1st place • Top 50 leaderboard"
	staked_desc.add_theme_font_size_override("font_size", 12)
	staked_desc.add_theme_color_override("font_color", Color(0.45, 0.35, 0.20, 1.0))
	staked_info.add_child(staked_desc)

	# Pool Selector Dropdown
	var pool_row = HBoxContainer.new()
	pool_row.add_theme_constant_override("separation", 10)
	staked_vbox.add_child(pool_row)

	var pool_select_lbl = Label.new()
	pool_select_lbl.text = "Select Pool:"
	pool_select_lbl.add_theme_font_size_override("font_size", 13)
	pool_select_lbl.add_theme_color_override("font_color", Color(0.24, 0.28, 0.28, 1.0))
	pool_row.add_child(pool_select_lbl)

	var option_btn = OptionButton.new()
	option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_btn.custom_minimum_size = Vector2(0, 32)
	var pools = PoolDataService.sample_pools
	for i in range(pools.size()):
		var p = pools[i]
		option_btn.add_item("%s (Stake: %s • Pot: %s)" % [p.get("name"), p.get("stake"), p.get("total_pot")], i)
	pool_row.add_child(option_btn)

	var stake_btn = Button.new()
	stake_btn.text = "Stake & Enter"
	stake_btn.custom_minimum_size = Vector2(130, 36)
	_style_button(stake_btn, btn_normal, btn_pressed, btn_hover, font_bold)
	stake_btn.pressed.connect(func():
		var chosen_idx = option_btn.selected
		if chosen_idx < 0 or chosen_idx >= pools.size():
			chosen_idx = 0
		var chosen_pool = pools[chosen_idx]
		overlay.queue_free()
		if has_node("/root/GlobalState"):
			var gs = get_node("/root/GlobalState")
			gs.active_run_mode = "staked"
			gs.active_run_pool = chosen_pool
		_launch_game()
	)
	pool_row.add_child(stake_btn)

	# Cancel Button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 32)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.flat = true
	cancel_btn.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
	cancel_btn.pressed.connect(func():
		overlay.queue_free()
	)
	vbox.add_child(cancel_btn)


func _style_button(btn: Button, normal_sb, pressed_sb, hover_sb, font_f):
	if normal_sb:
		btn.add_theme_stylebox_override("normal", normal_sb)
	if pressed_sb:
		btn.add_theme_stylebox_override("pressed", pressed_sb)
		btn.add_theme_stylebox_override("focus", pressed_sb)
	if hover_sb:
		btn.add_theme_stylebox_override("hover", hover_sb)
	if font_f:
		btn.add_theme_font_override("font", font_f)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.14, 0.18, 0.18, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.14, 0.18, 0.18, 1.0))


func _on_open_bets():
	if ResourceLoader.exists("res://scenes/menu/OpenBets.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/OpenBets.tscn")


func _on_how_to_play():
	if ResourceLoader.exists("res://scenes/menu/HowToPlay.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/HowToPlay.tscn")


func _on_credits():
	if ResourceLoader.exists("res://scenes/menu/Credits.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Credits.tscn")


func _on_account_info():
	if ResourceLoader.exists("res://scenes/menu/AccountInfo.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/AccountInfo.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
