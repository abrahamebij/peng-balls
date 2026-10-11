extends Control

@onready var connect_btn: Button = $ConnectBtn
@onready var header: Label = $Header
@onready var description: Label = $Description

const DEFAULT_DESCRIPTION := "Connect your Solana wallet to enter weekly speedrun pools and track your standings."


func _ready() -> void:
	connect_btn.pressed.connect(_on_connect_btn_pressed)

	# React to GlobalState events
	if GlobalState:
		GlobalState.wallet_connected.connect(_on_wallet_connected)
		GlobalState.wallet_disconnected.connect(_on_wallet_disconnected)
		GlobalState.wallet_connection_failed.connect(_on_wallet_connection_failed)
		
		# If already authenticated, redirect straight to main menu
		if GlobalState.is_connected:
			_switch_to_menu()
			return
		_update_ui_state()


func _on_connect_btn_pressed() -> void:
	if not GlobalState.is_connected:
		description.text = "Opening wallet selection..."
		GlobalState.open_wallet_modal()
	else:
		GlobalState.disconnect_wallet()


func _on_wallet_connected(_pubkey: String) -> void:
	description.text = "Connected! Loading menu..."
	_switch_to_menu()


func _on_wallet_disconnected() -> void:
	_update_ui_state()


func _on_wallet_connection_failed(_reason: String) -> void:
	description.text = "Connection cancelled or failed. Tap button to retry."
	_update_ui_state()


func _update_ui_state() -> void:
	if GlobalState.is_connected:
		connect_btn.text = "Disconnect"
		description.text = "Connected as: %s\n%s" % [GlobalState.wallet_provider_name, GlobalState.shorthand_pubkey]
	else:
		connect_btn.text = "Connect Wallet"
		description.text = DEFAULT_DESCRIPTION


func _switch_to_menu() -> void:
	if ResourceLoader.exists("res://scenes/menu/Menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")
