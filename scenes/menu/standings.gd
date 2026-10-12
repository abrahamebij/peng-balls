extends Control

@onready var pool_name_lbl: Label = $PoolBanner/PoolName
@onready var pool_details_lbl: Label = $PoolBanner/PoolDetails
@onready var table_rows_container: VBoxContainer = $ScrollContainer/TableRowsContainer
@onready var back_btn: Button = get_node_or_null("BackBtn")

var current_pool: Dictionary = {}


func _ready() -> void:
	# Enforce authentication
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return
		if gs.selected_pool != null and not gs.selected_pool.is_empty():
			current_pool = gs.selected_pool
		else:
			# Default to pool #1 if accessed directly
			current_pool = PoolDataService.sample_pools[0]

	if back_btn:
		back_btn.pressed.connect(_go_back)

	_render_pool_banner()
	_populate_table()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	if ResourceLoader.exists("res://scenes/menu/OpenBets.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/OpenBets.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")


func _render_pool_banner() -> void:
	pool_name_lbl.text = "%s — Top 50 Standings" % current_pool.get("name", "Community Pool")
	var pot_val: String = str(current_pool.get("total_pot", current_pool.get("totalPotFormatted", "0 SOL")))
	pool_details_lbl.text = "Stake: %s  •  Pot: %s  •  Time Left: %s" % [
		current_pool.get("stake", "0.05 SOL"),
		pot_val,
		current_pool.get("time_left", current_pool.get("timeLeft", "3d 14h"))
	]


func _populate_table() -> void:
	for child in table_rows_container.get_children():
		child.queue_free()

	var round_id: int = current_pool.get("round_id", current_pool.get("roundId", 1))
	var user_pubkey: String = ""
	if has_node("/root/GlobalState"):
		user_pubkey = get_node("/root/GlobalState").connected_pubkey

	var font_bold = load("res://resources/fonts/Poppins-Bold.ttf")

	# Initial render from distinct round standings
	var initial_standings = PoolDataService.get_top_50_standings(round_id, user_pubkey)
	for entry in initial_standings:
		var row = _create_table_row(entry, font_bold)
		table_rows_container.add_child(row)

	PoolDataService.fetch_standings(round_id, user_pubkey, self, func(standings: Array[Dictionary]):
		if not is_instance_valid(table_rows_container):
			return
		for child in table_rows_container.get_children():
			child.queue_free()
		if standings.is_empty():
			var empty_lbl = Label.new()
			empty_lbl.text = "No runs recorded in this pool yet. Enter a run to claim #1 on the leaderboard!"
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_font_size_override("font_size", 14)
			empty_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
			table_rows_container.add_child(empty_lbl)
			return
		for entry in standings:
			var row = _create_table_row(entry, font_bold)
			table_rows_container.add_child(row)
	)


func _create_table_row(entry: Dictionary, font_bold: Font) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 38)

	var is_player: bool = entry.get("is_player", false)
	var rank: int = entry.get("rank", 1)

	# Row Styling: Highlight if it is the current connected user
	var style = StyleBoxFlat.new()
	if is_player:
		# Highlighted row for the connected player
		style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		style.border_color = Color(0.14, 0.18, 0.18, 1.0)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
	else:
		# Clean alternating rows
		if rank % 2 == 0:
			style.bg_color = Color(1.0, 1.0, 1.0, 0.90)
		else:
			style.bg_color = Color(0.95, 0.95, 0.95, 0.90)
		style.border_color = Color(0.85, 0.85, 0.85, 0.6)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)

	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var text_color := Color(0.12, 0.15, 0.15, 1.0)

	# 1. Rank Column
	var rank_lbl = Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size = Vector2(80, 0)
	rank_lbl.add_theme_font_size_override("font_size", 15)
	rank_lbl.add_theme_color_override("font_color", text_color)
	if font_bold and (rank <= 3 or is_player):
		rank_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(rank_lbl)

	# 2. Player Address Column
	var player_lbl = Label.new()
	if is_player:
		player_lbl.text = "%s (YOU)" % entry.get("shorthand", "")
		if font_bold:
			player_lbl.add_theme_font_override("font", font_bold)
	else:
		player_lbl.text = entry.get("shorthand", "")

	player_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_lbl.add_theme_font_size_override("font_size", 15)
	player_lbl.add_theme_color_override("font_color", text_color)
	hbox.add_child(player_lbl)

	# 3. Best Time Column
	var time_lbl = Label.new()
	time_lbl.text = entry.get("formatted_time", "00:00.00")
	time_lbl.custom_minimum_size = Vector2(130, 0)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.add_theme_font_size_override("font_size", 15)
	time_lbl.add_theme_color_override("font_color", text_color)
	if font_bold and is_player:
		time_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(time_lbl)

	# 4. Wins Column
	var wins_lbl = Label.new()
	wins_lbl.text = "%d W" % entry.get("wins", 0)
	wins_lbl.custom_minimum_size = Vector2(85, 0)
	wins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wins_lbl.add_theme_font_size_override("font_size", 15)
	wins_lbl.add_theme_color_override("font_color", Color(0.10, 0.50, 0.15, 1.0))
	if font_bold:
		wins_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(wins_lbl)

	# 5. Losses Column
	var losses_lbl = Label.new()
	losses_lbl.text = "%d L" % entry.get("losses", 0)
	losses_lbl.custom_minimum_size = Vector2(85, 0)
	losses_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	losses_lbl.add_theme_font_size_override("font_size", 15)
	losses_lbl.add_theme_color_override("font_color", Color(0.70, 0.20, 0.15, 1.0))
	if font_bold:
		losses_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(losses_lbl)

	return panel
