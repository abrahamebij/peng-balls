extends Control

@onready var address_value: Label = $WalletAddress/Value
@onready var copy_btn: Button = $WalletAddress/CopyBtn
@onready var copied_label: Label = $WalletAddress/CopiedLabel
@onready var balance_value: Label = $Balance/Value
@onready var disconnect_btn: Button = $DisconnectBtn
@onready var back_btn: Button = get_node_or_null("BackBtn")

var _copied_timer: SceneTreeTimer = null


func _ready() -> void:
	# Enforce authentication: no unauthenticated user can access this screen
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return
		
		gs.balance_updated.connect(_on_balance_updated)
		gs.wallet_disconnected.connect(_on_wallet_disconnected)
		_refresh_account_data()
	
	if copy_btn:
		copy_btn.pressed.connect(_on_copy_pressed)
	if disconnect_btn:
		disconnect_btn.pressed.connect(_on_disconnect_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _refresh_account_data() -> void:
	if not has_node("/root/GlobalState"):
		return
	var gs = get_node("/root/GlobalState")
	
	if gs.is_connected:
		address_value.text = gs.shorthand_pubkey if not gs.shorthand_pubkey.is_empty() else gs.connected_pubkey
		balance_value.text = "%.4f SOL" % gs.sol_balance
		gs.fetch_balance()
	else:
		address_value.text = "Not Connected"
		balance_value.text = "-- SOL"


func _on_balance_updated(new_balance: float) -> void:
	balance_value.text = "%.4f SOL" % new_balance


func _on_copy_pressed() -> void:
	if not has_node("/root/GlobalState"):
		return
	var gs = get_node("/root/GlobalState")
	if gs.is_connected and not gs.connected_pubkey.is_empty():
		DisplayServer.clipboard_set(gs.connected_pubkey)
		if copied_label:
			copied_label.visible = true
			if _copied_timer:
				_copied_timer = null
			_copied_timer = get_tree().create_timer(2.0)
			_copied_timer.timeout.connect(func():
				if is_instance_valid(copied_label):
					copied_label.visible = false
			)


func _on_disconnect_pressed() -> void:
	if has_node("/root/GlobalState"):
		get_node("/root/GlobalState").disconnect_wallet()
	get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")


func _on_wallet_disconnected() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")
