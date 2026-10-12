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
	PoolDataService.fetch_pools(self, func(_pools):
		_populate_pools()
	)


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

	# Initial render from local cache
	var pools = PoolDataService.sample_pools
	for pool in pools:
		var card = _create_pool_card(pool)
		pools_container.add_child(card)

	# Asynchronously update from backend
	PoolDataService.fetch_pools(self, func(live_pools: Array[Dictionary]):
		if not is_instance_valid(pools_container) or live_pools.is_empty():
			return
		for child in pools_container.get_children():
			child.queue_free()
		for pool in live_pools:
			var card = _create_pool_card(pool)
			pools_container.add_child(card)
	)


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

	# Clean description: only Pot and Leader
	var stats_lbl = Label.new()
	var pot_val: String = str(pool.get("total_pot", pool.get("totalPotFormatted", "0 SOL")))
	stats_lbl.text = "Pot: %s" % pot_val
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.add_theme_color_override("font_color", Color(0.18, 0.22, 0.22, 1.0))
	if font_bold:
		stats_lbl.add_theme_font_override("font", font_bold)
	left_vbox.add_child(stats_lbl)

	# Leader & Timer line
	var leader_lbl = Label.new()
	var leader_val: String = str(pool.get("current_leader", pool.get("currentLeader", "--")))
	var best_val: String = str(pool.get("best_time", pool.get("bestTimeFormatted", "--")))
	leader_lbl.text = "Time Left: %s  •  Leader: %s (%s)" % [
		pool.get("time_left", pool.get("timeLeft", "--")),
		leader_val,
		best_val
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
		_enter_pool_run(pool, enter_btn)
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


func _enter_pool_run(pool: Dictionary, action_btn: Button = null) -> void:
	if not has_node("/root/GlobalState"):
		return
	var gs = get_node("/root/GlobalState")

	var fee_lamports: int = pool.get("entry_fee_lamports", pool.get("entryFeeLamports", 50000000))
	var fee_sol: float = float(fee_lamports) / 1_000_000_000.0

	# Balance pre-check
	if gs.sol_balance < fee_sol and gs.wallet_provider_id != 999:
		print("[OpenBets] Insufficient SOL balance: %.4f required, user has %.4f" % [fee_sol, gs.sol_balance])

	var tx_signature: String = ""

	# If connected with real Phantom / Solana wallet (not desktop dev bypass), trigger real transaction
	if gs.wallet_provider_id != 999 and has_node("/root/SolanaService"):
		var solana_service = get_node("/root/SolanaService")
		if solana_service and solana_service.has_node("TransactionManager"):
			var tx_mgr = solana_service.get_node("TransactionManager")
			var vault_addr: String = str(pool.get("vaultPubkey", pool.get("vault_pubkey", "2G9MvvQTCjFmNn3Bm98ibJ34cCsW2eXEoieWtsRiRnpf")))
			var vault_pk = Pubkey.new_from_string(vault_addr)

			if action_btn:
				action_btn.disabled = true
				action_btn.text = "Approve in Phantom..."

			print("[OpenBets] Triggering Phantom transaction for %.4f SOL to %s" % [fee_sol, vault_addr])
			var tx_data: TransactionData = await tx_mgr.transfer_sol(vault_pk, fee_sol)

			if action_btn:
				action_btn.disabled = false
				action_btn.text = "Enter Run (%s)" % pool.get("stake", "")

			if tx_data == null or not tx_data.is_successful():
				print("[OpenBets] Transaction was rejected or cancelled in Phantom.")
				return

			tx_signature = str(tx_data.data.get("result", ""))
			print("[OpenBets] Phantom transaction confirmed on Devnet! Signature: ", tx_signature)

	# Register run entry with backend
	PoolDataService.enter_pool(pool, gs.connected_pubkey, self, func(_ok, _msg):
		gs.active_run_mode = "staked"
		gs.active_run_pool = pool
		gs.next_scene_path = "res://scenes/game/Game.tscn"

		if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
			get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
	)
