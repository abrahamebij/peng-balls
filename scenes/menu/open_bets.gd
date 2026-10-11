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
	style.bg_color = Color(0.96, 0.94, 0.88, 0.92)
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
	stats_lbl.text = "💰 Pot: %s  •  Winner Takes (90%%): %s  •  Runs: %d" % [
		pool.get("total_pot", "0 SOL"),
		pool.get("winner_cut", "0 SOL"),
		pool.get("total_runs", 0)
	]
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", Color(0.25, 0.30, 0.30, 1.0))
	left_vbox.add_child(stats_lbl)

	# Leader & Timer line
	var leader_lbl = Label.new()
	leader_lbl.text = "⏱️ Time Left: %s  •  Current 1st: %s (%s)" % [
		pool.get("time_left", "--"),
		pool.get("current_leader", "--"),
		pool.get("best_time", "--")
	]
	leader_lbl.add_theme_font_size_override("font_size", 13)
	leader_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
	left_vbox.add_child(leader_lbl)

	# Right Column: View Standings Action Button
	var action_btn = Button.new()
	action_btn.text = "View Standings\n(Top 50)"
	action_btn.custom_minimum_size = Vector2(160, 56)
	action_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var btn_normal = load("res://styles/menu-btn.tres")
	var btn_pressed = load("res://styles/menu-btn-pressed.tres")
	var btn_hover = load("res://styles/menu-btn-hovered.tres")
	if btn_normal:
		action_btn.add_theme_stylebox_override("normal", btn_normal)
	if btn_pressed:
		action_btn.add_theme_stylebox_override("pressed", btn_pressed)
		action_btn.add_theme_stylebox_override("focus", btn_pressed)
	if btn_hover:
		action_btn.add_theme_stylebox_override("hover", btn_hover)
	if font_bold:
		action_btn.add_theme_font_override("font", font_bold)
	action_btn.add_theme_font_size_override("font_size", 14)
	action_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
	action_btn.add_theme_color_override("font_hover_color", Color(0.14, 0.18, 0.18, 1.0))
	action_btn.add_theme_color_override("font_pressed_color", Color(0.14, 0.18, 0.18, 1.0))

	action_btn.pressed.connect(func():
		_open_standings_for_pool(pool)
	)
	hbox.add_child(action_btn)

	return panel


func _open_standings_for_pool(pool: Dictionary) -> void:
	if has_node("/root/GlobalState"):
		get_node("/root/GlobalState").selected_pool = pool
	if ResourceLoader.exists("res://scenes/menu/Standings.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Standings.tscn")
