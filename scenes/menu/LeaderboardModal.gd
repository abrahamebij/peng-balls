extends Control
# LeaderboardModal.gd

@onready var pool_pot_label = $Panel/VBoxContainer/Header/PotLabel
@onready var best_time_label = $Panel/VBoxContainer/Header/BestTimeLabel
@onready var time_left_label = $Panel/VBoxContainer/Header/TimeLeftLabel
@onready var player_stats_label = $Panel/VBoxContainer/PlayerStatsLabel
@onready var list_container = $Panel/VBoxContainer/ScrollContainer/ListVBox
@onready var wallet_btn = $Panel/VBoxContainer/Footer/WalletButton
@onready var bet_play_btn = $Panel/VBoxContainer/Footer/BetPlayButton
@onready var close_btn = $Panel/VBoxContainer/Footer/CloseButton

@onready var skr_tab_btn = $Panel/VBoxContainer/CurrencyTabs/SKRButton
@onready var devcoin_tab_btn = $Panel/VBoxContainer/CurrencyTabs/DevCoinButton


func _ready():
	visible = false
	close_btn.pressed.connect(_on_close)
	wallet_btn.pressed.connect(_on_wallet_toggle)
	bet_play_btn.pressed.connect(_on_bet_play)
	
	if skr_tab_btn:
		skr_tab_btn.pressed.connect(func(): _switch_currency(0))
	if devcoin_tab_btn:
		devcoin_tab_btn.pressed.connect(func(): _switch_currency(1))

	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		mgr.wallet_connected.connect(_on_wallet_updated)
		mgr.wallet_disconnected.connect(_on_wallet_updated)
		mgr.pool_updated.connect(_on_pool_updated)
		mgr.currency_switched.connect(_on_currency_switched)

	refresh_display()


func _switch_currency(mode: int):
	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		mgr.set_currency(mode as SolanaPoolManager.Currency)


func _on_currency_switched(_name):
	refresh_display()


func refresh_display():
	if not has_node("/root/SolanaPoolManager"):
		return
	var mgr = get_node("/root/SolanaPoolManager")

	var cur_name = mgr.get_active_currency_name()
	var pot_val = int(mgr.get_active_pot())
	var winner_payout = int(pot_val * 0.9)

	pool_pot_label.text = "Weekly Pool: %d %s (Winner takes %d %s [90%%])" % [
		pot_val, cur_name, winner_payout, cur_name
	]
	var best_time_text = mgr.get_formatted_time(mgr.best_time_ms) if mgr.best_time_ms > 0 else "--:--"
	best_time_label.text = "1st Place Time: " + best_time_text
	time_left_label.text = "Solana Devnet | " + mgr.PROGRAM_ID.substr(0, 4) + "..." + mgr.PROGRAM_ID.substr(mgr.PROGRAM_ID.length() - 4)

	var best_str = mgr.get_formatted_time(mgr.player_best_time_ms) if mgr.player_best_time_ms > 0 else "--:--"
	player_stats_label.text = "Your Record: %d Wins | %d Losses | Best: %s | Bal: %d %s" % [
		mgr.player_wins, mgr.player_losses, best_str, int(mgr.get_active_balance()), cur_name
	]

	bet_play_btn.text = "Bet & Play (%d %s)" % [int(mgr.get_active_entry_fee()), cur_name]

	if mgr.is_connected:
		wallet_btn.text = "MWA: " + mgr.wallet_address.substr(0, 4) + "..." + mgr.wallet_address.substr(mgr.wallet_address.length() - 4)
	else:
		wallet_btn.text = "Connect (MWA)"

	# Populate leaderboard items
	for child in list_container.get_children():
		child.queue_free()

	if mgr.leaderboard.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No runs recorded yet.\nComplete a maze run to set a record!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		list_container.add_child(empty_lbl)
	else:
		for entry in mgr.leaderboard:
			var row = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var rank_lbl = Label.new()
			rank_lbl.text = "#" + str(entry["rank"])
			rank_lbl.custom_minimum_size = Vector2(40, 24)

			var name_lbl = Label.new()
			name_lbl.text = entry["player"]
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var time_lbl = Label.new()
			time_lbl.text = entry["time_str"]
			time_lbl.custom_minimum_size = Vector2(80, 24)
			time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

			row.add_child(rank_lbl)
			row.add_child(name_lbl)
			row.add_child(time_lbl)
			list_container.add_child(row)


func _on_wallet_updated(_addr = ""):
	refresh_display()


func _on_pool_updated(_pot, _time_str):
	refresh_display()


func _on_wallet_toggle():
	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		if mgr.is_connected:
			mgr.disconnect_wallet()
		else:
			mgr.connect_wallet()


func _on_bet_play():
	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		if mgr.enter_pool_run():
			get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _on_close():
	visible = false
