extends Control

@onready var leaderboard_modal = $LeaderboardModal
@onready var start_button = $VBoxContainer/StartButton
@onready var leaderboard_button = $VBoxContainer/LeaderboardButton
@onready var pool_banner = get_node_or_null("TopBar/PoolBanner")
@onready var top_wallet_button = get_node_or_null("TopBar/TopWalletButton")


func _ready():
	start_button.pressed.connect(_on_start)
	leaderboard_button.pressed.connect(_on_leaderboard)

	if top_wallet_button:
		top_wallet_button.pressed.connect(_on_wallet_toggle)

	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		mgr.wallet_connected.connect(_on_wallet_changed)
		mgr.wallet_disconnected.connect(_on_wallet_changed)
		mgr.pool_updated.connect(_on_pool_changed)
		mgr.currency_switched.connect(_on_currency_changed)
	
	_update_header()


func _update_header():
	if not has_node("/root/SolanaPoolManager"):
		return
	var mgr = get_node("/root/SolanaPoolManager")

	if pool_banner:
		var cur_name = mgr.get_active_currency_name()
		var pot_val = int(mgr.get_active_pot())
		var winner_cut = int(pot_val * 0.9)
		pool_banner.text = "WEEKLY POOL: %d %s | 90%% WINNER: %d %s" % [
			pot_val, cur_name, winner_cut, cur_name
		]

	if top_wallet_button:
		if mgr.is_connected:
			top_wallet_button.text = "MWA: " + mgr.wallet_address
		else:
			top_wallet_button.text = "Connect (MWA)"


func _on_wallet_changed(_addr = ""):
	_update_header()


func _on_pool_changed(_pot = 0, _best = ""):
	_update_header()


func _on_currency_changed(_c_name = ""):
	_update_header()


func _on_wallet_toggle():
	if has_node("/root/SolanaPoolManager"):
		var mgr = get_node("/root/SolanaPoolManager")
		if mgr.is_connected:
			mgr.disconnect_wallet()
		else:
			mgr.connect_wallet()


func _on_start():
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _on_leaderboard():
	if leaderboard_modal:
		leaderboard_modal.refresh_display()
		leaderboard_modal.visible = true
