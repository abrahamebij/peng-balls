extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var open_bets_button = get_node_or_null("VBoxContainer/OpenBetsButton")
@onready var how_to_play_button = get_node_or_null("VBoxContainer/HowToPlayButton")
@onready var credits_button = get_node_or_null("VBoxContainer/CreditsButton")
@onready var account_info_button = get_node_or_null("AccountInfo")

# Mode Select Modal in Menu.tscn
@onready var mode_select_modal = get_node_or_null("ModeSelectModal")
@onready var play_free_btn = get_node_or_null("ModeSelectModal/ModalPanel/VBox/CasualCard/HBox/PlayFreeBtn")
@onready var stake_btn = get_node_or_null("ModeSelectModal/ModalPanel/VBox/StakedCard/VBox/PoolRow/StakeBtn")
@onready var pool_option_btn = get_node_or_null("ModeSelectModal/ModalPanel/VBox/StakedCard/VBox/PoolRow/PoolOptionBtn")
@onready var cancel_btn = get_node_or_null("ModeSelectModal/ModalPanel/VBox/CancelBtn")


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

	_setup_mode_select_modal()


func _setup_mode_select_modal():
	if not mode_select_modal:
		return
	mode_select_modal.visible = false

	# Populate pool dropdown
	if pool_option_btn:
		pool_option_btn.clear()
		var pools = PoolDataService.sample_pools
		for i in range(pools.size()):
			var p = pools[i]
			pool_option_btn.add_item("%s (Stake: %s • Pot: %s)" % [p.get("name"), p.get("stake"), p.get("total_pot")], i)

	if play_free_btn:
		play_free_btn.pressed.connect(func():
			mode_select_modal.visible = false
			if has_node("/root/GlobalState"):
				var gs = get_node("/root/GlobalState")
				gs.active_run_mode = "casual"
				gs.active_run_pool = {}
			_launch_game()
		)

	if stake_btn:
		stake_btn.pressed.connect(func():
			var pools = PoolDataService.sample_pools
			var chosen_idx = pool_option_btn.selected if pool_option_btn else 0
			if chosen_idx < 0 or chosen_idx >= pools.size():
				chosen_idx = 0
			mode_select_modal.visible = false
			if has_node("/root/GlobalState"):
				var gs = get_node("/root/GlobalState")
				gs.active_run_mode = "staked"
				gs.active_run_pool = pools[chosen_idx]
			_launch_game()
		)

	if cancel_btn:
		cancel_btn.pressed.connect(func():
			mode_select_modal.visible = false
		)


func _on_start():
	if mode_select_modal:
		mode_select_modal.visible = true
	else:
		_launch_game()


func _launch_game():
	if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
		if has_node("/root/GlobalState"):
			get_node("/root/GlobalState").next_scene_path = "res://scenes/game/Game.tscn"
		get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


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
