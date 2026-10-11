extends Control

@onready var pools_container: VBoxContainer = $ScrollContainer/PoolsContainer
@onready var back_btn: Button = get_node_or_null("BackBtn")


func _ready() -> void:
	# Enforce authentication
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return

	if back_btn:
		back_btn.pressed.connect(_go_back)

	_populate_pools()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")


func _populate_pools() -> void:
	# Clear previous items
	for child in pools_container.get_children():
		child.queue_free()

	var pools = PoolDataService.sample_pools
	for pool in pools:
		var card = _create_pool_card(pool)
		pools_container.add_child(card)


func _create_pool_card(pool: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 110)

	# Card style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.98)
	style.border_color = Color(0.24, 0.28, 0.28, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	# Left Column: Info
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(left_vbox)

	# Title & Stake Badge
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	left_vbox.add_child(title_row)

	var title_lbl = Label.new()
	title_lbl.text = pool.get("name", "Weekly Pool")
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.14, 0.18, 0.18, 1.0))
	var font_bold = load("res://resources/fonts/Poppins-Bold.ttf")
	if font_bold:
		title_lbl.add_theme_font_override("font", font_bold)
	title_row.add_child(title_lbl)

	var badge = Label.new()
	badge.text = "[Stake: %s]" % pool.get("stake", "0.05 SOL")
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", Color(0.75, 0.45, 0.05, 1.0))
	if font_bold:
		badge.add_theme_font_override("font", font_bold)
	title_row.add_child(badge)

	# Stats line
	var stats_lbl = Label.new()
	stats_lbl.text = "Pot: %s  •  Winner Takes (90%%): %s  •  Runs: %d" % [
		pool.get("total_pot", "0 SOL"),
		pool.get("winner_cut", "0 SOL"),
		pool.get("total_runs", 0)
	]
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", Color(0.25, 0.30, 0.30, 1.0))
	left_vbox.add_child(stats_lbl)

	# Leader & Timer line
	var leader_lbl = Label.new()
	leader_lbl.text = "Time Left: %s  •  Current 1st: %s (%s)" % [
		pool.get("time_left", "--"),
		pool.get("current_leader", "--"),
		pool.get("best_time", "--")
	]
	leader_lbl.add_theme_font_size_override("font_size", 13)
	leader_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
	left_vbox.add_child(leader_lbl)

	# Right Column: Action Buttons (Enter Run & View Standings)
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(right_vbox)

	var btn_normal = load("res://styles/menu-btn.tres")
	var btn_pressed = load("res://styles/menu-btn-pressed.tres")
	var btn_hover = load("res://styles/menu-btn-hovered.tres")

	# 1. Enter Run Button
	var enter_btn = Button.new()
	enter_btn.text = "Enter Run (%s)" % pool.get("stake", "")
	enter_btn.custom_minimum_size = Vector2(170, 36)
	if btn_normal:
		enter_btn.add_theme_stylebox_override("normal", btn_normal)
	if btn_pressed:
		enter_btn.add_theme_stylebox_override("pressed", btn_pressed)
		enter_btn.add_theme_stylebox_override("focus", btn_pressed)
	if btn_hover:
		enter_btn.add_theme_stylebox_override("hover", btn_hover)
	if font_bold:
		enter_btn.add_theme_font_override("font", font_bold)
	enter_btn.add_theme_font_size_override("font_size", 12)
	enter_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
	enter_btn.add_theme_color_override("font_hover_color", Color(0.14, 0.18, 0.18, 1.0))
	enter_btn.add_theme_color_override("font_pressed_color", Color(0.14, 0.18, 0.18, 1.0))

	enter_btn.pressed.connect(func():
		_enter_pool_run(pool)
	)
	right_vbox.add_child(enter_btn)

	# 2. View Standings Button
	var standings_btn = Button.new()
	standings_btn.text = "Standings (Top 50)"
	standings_btn.custom_minimum_size = Vector2(170, 32)
	if btn_normal:
		standings_btn.add_theme_stylebox_override("normal", btn_normal)
	if btn_pressed:
		standings_btn.add_theme_stylebox_override("pressed", btn_pressed)
		standings_btn.add_theme_stylebox_override("focus", btn_pressed)
	if btn_hover:
		standings_btn.add_theme_stylebox_override("hover", btn_hover)
	if font_bold:
		standings_btn.add_theme_font_override("font", font_bold)
	standings_btn.add_theme_font_size_override("font_size", 12)
	standings_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
	standings_btn.add_theme_color_override("font_hover_color", Color(0.14, 0.18, 0.18, 1.0))
	standings_btn.add_theme_color_override("font_pressed_color", Color(0.14, 0.18, 0.18, 1.0))

	standings_btn.pressed.connect(func():
		_open_standings_for_pool(pool)
	)
	right_vbox.add_child(standings_btn)

	return panel


func _open_standings_for_pool(pool: Dictionary) -> void:
	if has_node("/root/GlobalState"):
		get_node("/root/GlobalState").selected_pool = pool
	if ResourceLoader.exists("res://scenes/menu/Standings.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Standings.tscn")


func _enter_pool_run(pool: Dictionary) -> void:
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		gs.active_run_mode = "staked"
		gs.active_run_pool = pool
		gs.next_scene_path = "res://scenes/game/Game.tscn"
	if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
