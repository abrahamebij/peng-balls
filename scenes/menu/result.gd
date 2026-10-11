extends Control

@onready var outcome_lbl: Label = $Card/VBox/Outcome
@onready var mode_lbl: Label = $Card/VBox/ModeValue
@onready var time_lbl: Label = $Card/VBox/TimeValue
@onready var coins_lbl: Label = $Card/VBox/CoinsValue
@onready var standing_lbl: Label = $Card/VBox/StandingValue
@onready var standings_btn: Button = $Card/VBox/Buttons/StandingsBtn
@onready var play_again_btn: Button = $Card/VBox/Buttons/PlayAgainBtn
@onready var menu_btn: Button = $Card/VBox/Buttons/MenuBtn


func _ready() -> void:
	# Enforce authentication
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return

	if standings_btn:
		standings_btn.pressed.connect(_on_view_standings)
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)

	_populate_results()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu()


func _populate_results() -> void:
	var result := {}
	if has_node("/root/GlobalState"):
		result = get_node("/root/GlobalState").last_run_result

	var won: bool = result.get("won", false)
	var mode: String = result.get("mode", "casual")
	var pool: Dictionary = result.get("pool", {})
	var time_formatted: String = result.get("time_formatted", "00:00.00")
	var coins_collected: int = result.get("coins_collected", 0)
	var coins_total: int = result.get("coins_total", 0)
	var estimated_rank: int = result.get("estimated_rank", -1)

	# 1. Outcome
	if won:
		outcome_lbl.text = "VICTORY! MAZE CLEARED"
		outcome_lbl.add_theme_color_override("font_color", Color(0.15, 0.60, 0.25, 1.0))
	else:
		outcome_lbl.text = "CAUGHT BY ENEMY!"
		outcome_lbl.add_theme_color_override("font_color", Color(0.75, 0.20, 0.15, 1.0))

	# 2. Mode
	if mode == "staked" and not pool.is_empty():
		mode_lbl.text = "%s (Stake: %s)" % [pool.get("name", "Pool"), pool.get("stake", "")]
		mode_lbl.add_theme_color_override("font_color", Color(0.14, 0.18, 0.18, 1.0))
		standings_btn.visible = true
	else:
		mode_lbl.text = "Practice Run (Free)"
		mode_lbl.add_theme_color_override("font_color", Color(0.25, 0.35, 0.35, 1.0))
		standings_btn.visible = false

	# 3. Time & Coins
	time_lbl.text = time_formatted
	coins_lbl.text = "%d / %d Collected" % [coins_collected, coins_total]

	# 4. Standing
	if mode == "staked":
		if won:
			if estimated_rank > 0:
				standing_lbl.text = "Projected Rank #%d in Weekly Pool" % estimated_rank
				standing_lbl.add_theme_color_override("font_color", Color(0.15, 0.55, 0.20, 1.0))
			else:
				standing_lbl.text = "Run recorded in weekly pool stats."
				standing_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))
		else:
			standing_lbl.text = "Run ended in defeat. 1 loss recorded in pool stats."
			standing_lbl.add_theme_color_override("font_color", Color(0.65, 0.25, 0.20, 1.0))
	else:
		standing_lbl.text = "Free practice run. Times are tracked locally and not entered in pool pot."
		standing_lbl.add_theme_color_override("font_color", Color(0.35, 0.40, 0.40, 1.0))


func _on_view_standings() -> void:
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.last_run_result.get("pool", {}).is_empty():
			gs.selected_pool = gs.last_run_result.get("pool")
	if ResourceLoader.exists("res://scenes/menu/Standings.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Standings.tscn")


func _on_play_again() -> void:
	if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
		if has_node("/root/GlobalState"):
			get_node("/root/GlobalState").next_scene_path = "res://scenes/game/Game.tscn"
		get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _on_menu() -> void:
	if ResourceLoader.exists("res://scenes/menu/Menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")
