extends Node

## GlobalState — Autoload singleton managing game-wide Solana wallet state,
## connection lifecycle, balances, and UI modal dispatch.

signal wallet_connected(pubkey: String)
signal wallet_disconnected
signal wallet_connection_failed(error_message: String)
signal balance_updated(new_balance: float)
signal skr_balance_updated(new_balance: float)

# Connection state
var is_connected: bool = false
var connected_pubkey: String = ""
var shorthand_pubkey: String = ""
var wallet_provider_id: int = -1
var wallet_provider_name: String = ""
var sol_balance: float = 0.0
var skr_balance: float = 0.0
var next_scene_path: String = ""
var selected_pool: Dictionary = {}

# Active run configuration: "casual" (free / fun) or "staked" (community pool)
var active_run_mode: String = "casual"
var active_run_pool: Dictionary = {}

# Last run results to display on Result.tscn
var last_run_result: Dictionary = {
	"won": false,
	"time_elapsed": 0.0,
	"time_formatted": "00:00.00",
	"time_ms": 0,
	"mode": "casual",
	"pool": {},
	"coins_collected": 0,
	"coins_total": 0,
	"estimated_rank": -1
}

# Supported wallet IDs mapped to readable names
const WALLET_NAMES: Dictionary = {
	20: "Phantom",
	25: "Solflare",
	36: "Backpack",
	999: "Dev Bypass (Chlorine)"
}

var _secret_buffer: String = ""
const SECRET_KEYWORD: String = "chlorine"
const SESSION_SAVE_PATH: String = "user://wallet_session.json"

func _ready() -> void:
	# Attempt to restore persisted session from previous run
	_load_session()
	
	# Give the scene tree a frame to ensure all autoloads are mounted
	await get_tree().process_frame
	_hook_solana_service()


func _save_session() -> void:
	var data := {
		"connected_pubkey": connected_pubkey,
		"wallet_provider_id": wallet_provider_id,
		"wallet_provider_name": wallet_provider_name,
		"is_connected": is_connected,
		"sol_balance": sol_balance,
		"skr_balance": skr_balance
	}
	var file = FileAccess.open(SESSION_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("[GlobalState] Saved wallet session to ", SESSION_SAVE_PATH)


func _load_session() -> bool:
	if not FileAccess.file_exists(SESSION_SAVE_PATH):
		return false
	var file = FileAccess.open(SESSION_SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) != OK:
		return false
	var data = json.get_data()
	if not (data is Dictionary):
		return false
	
	var pubkey: String = data.get("connected_pubkey", "")
	if pubkey.is_empty():
		return false
	
	connected_pubkey = pubkey
	shorthand_pubkey = get_shorthand(connected_pubkey)
	wallet_provider_id = data.get("wallet_provider_id", -1)
	wallet_provider_name = data.get("wallet_provider_name", "Solana Wallet")
	sol_balance = float(data.get("sol_balance", 0.0))
	skr_balance = float(data.get("skr_balance", 0.0))
	is_connected = true
	print("[GlobalState] Restored saved session: %s (%s)" % [connected_pubkey, wallet_provider_name])
	
	wallet_connected.emit(connected_pubkey)
	fetch_balance()
	return true


func _clear_session() -> void:
	if FileAccess.file_exists(SESSION_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_SAVE_PATH))
		print("[GlobalState] Cleared saved wallet session")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var char_typed := ""
		if event.unicode > 0:
			char_typed = String.chr(event.unicode).to_lower()
		elif event.keycode >= KEY_A and event.keycode <= KEY_Z:
			char_typed = char(event.keycode).to_lower()
		
		if not char_typed.is_empty():
			_secret_buffer += char_typed
			if _secret_buffer.length() > 30:
				_secret_buffer = _secret_buffer.substr(_secret_buffer.length() - 30)
			
			if _secret_buffer.ends_with(SECRET_KEYWORD):
				_secret_buffer = ""
				activate_dev_bypass()


func _hook_solana_service() -> void:
	if has_node("/root/SolanaService"):
		var solana_service = get_node("/root/SolanaService")
		if solana_service.has_method("set_rpc_cluster") and "RpcCluster" in solana_service:
			solana_service.set_rpc_cluster(solana_service.RpcCluster.DEVNET)
			print("[GlobalState] Configured SolanaService to DEVNET")
		if solana_service and solana_service.has_node("WalletService"):
			var wallet_svc = solana_service.get_node("WalletService")
			if not wallet_svc.on_login_success.is_connected(_on_wallet_login_success):
				wallet_svc.on_login_success.connect(_on_wallet_login_success)
			if not wallet_svc.on_login_fail.is_connected(_on_wallet_login_fail):
				wallet_svc.on_login_fail.connect(_on_wallet_login_fail)
			print("[GlobalState] Successfully connected to SolanaService.WalletService")
		else:
			print("[GlobalState] SolanaService found but WalletService node is missing")
	else:
		print("[GlobalState] SolanaService autoload not found in root")


## Opens the wallet selection modal to let the user pick an available wallet
func open_wallet_modal() -> void:
	print("[GlobalState] open_wallet_modal requested")
	if has_node("/root/SolanaService"):
		var solana_service = get_node("/root/SolanaService")
		if solana_service and solana_service.has_node("WalletService"):
			var wallet_svc = solana_service.get_node("WalletService")
			wallet_svc.try_login()
			return

	# Fallback if SolanaService isn't in tree
	_spawn_wallet_adapter_ui_fallback()


## Fallback instantiation of WalletAdapterUI directly
func _spawn_wallet_adapter_ui_fallback() -> void:
	var adapter_ui_scene = load("res://addons/SolanaSDK/Optional/SolanaService/Scripts/WalletAdapter/WalletAdapterUI.tscn")
	if adapter_ui_scene:
		var modal = adapter_ui_scene.instantiate()
		get_tree().root.add_child(modal)
		if modal.has_method("setup_adapter"):
			modal.setup_adapter([])
		if modal.has_signal("on_provider_selected"):
			modal.on_provider_selected.connect(_on_fallback_provider_selected)
		print("[GlobalState] Instantiated WalletAdapterUI modal via fallback")
	else:
		push_error("[GlobalState] Could not load WalletAdapterUI scene")


func _on_fallback_provider_selected(provider_id: int) -> void:
	print("[GlobalState] Fallback provider selected: ", provider_id)
	wallet_provider_id = provider_id
	wallet_provider_name = WALLET_NAMES.get(provider_id, "Wallet %d" % provider_id)
	if has_node("/root/SolanaService"):
		var solana_service = get_node("/root/SolanaService")
		if solana_service and solana_service.has_node("WalletService"):
			var wallet_svc = solana_service.get_node("WalletService")
			wallet_svc.login_adapter(provider_id)


func _on_wallet_login_success() -> void:
	var solana_service = get_node_or_null("/root/SolanaService")
	if solana_service and solana_service.has_node("WalletService"):
		var wallet_svc = solana_service.get_node("WalletService")
		var key_obj = wallet_svc.get_pubkey()
		connected_pubkey = _extract_pubkey_string(key_obj)
		if connected_pubkey.is_empty() and Engine.has_singleton("WalletAdapterAndroid"):
			var plugin = Engine.get_singleton("WalletAdapterAndroid")
			var b58: String = str(plugin.call("getConnectedKeyBase58"))
			if not b58.is_empty():
				connected_pubkey = b58
		wallet_provider_id = wallet_svc.get_wallet_provider_id()
		wallet_provider_name = WALLET_NAMES.get(wallet_provider_id, "Solana Wallet")

	is_connected = true
	shorthand_pubkey = get_shorthand(connected_pubkey)
	print("[GlobalState] Wallet Connected: %s (%s)" % [connected_pubkey, shorthand_pubkey])
	_save_session()
	wallet_connected.emit(connected_pubkey)

	fetch_balance()


func _on_wallet_login_fail() -> void:
	print("[GlobalState] Wallet Login Failed or Cancelled")
	wallet_connection_failed.emit("Wallet connection cancelled or failed")


func disconnect_wallet() -> void:
	is_connected = false
	connected_pubkey = ""
	shorthand_pubkey = ""
	wallet_provider_id = -1
	wallet_provider_name = ""
	sol_balance = 0.0
	skr_balance = 0.0
	_clear_session()
	print("[GlobalState] Wallet Disconnected")
	wallet_disconnected.emit()


## Applies dummy data to GlobalState as pretend authentication for desktop testing
func activate_dev_bypass() -> void:
	print("[GlobalState] *** DEV BYPASS ACTIVATED (Keyword: Chlorine) ***")
	is_connected = true
	connected_pubkey = "DeV1LapToPpReTeNdWaLLeT111111111111111111111"
	shorthand_pubkey = get_shorthand(connected_pubkey)
	wallet_provider_id = 999
	wallet_provider_name = "Dev Bypass (Chlorine)"
	sol_balance = 25.50
	skr_balance = 0.0
	_save_session()
	
	wallet_connected.emit(connected_pubkey)
	balance_updated.emit(sol_balance)
	skr_balance_updated.emit(skr_balance)


func fetch_balance() -> void:
	if not is_connected or connected_pubkey.is_empty():
		return
	if wallet_provider_id == 999:
		balance_updated.emit(sol_balance)
		skr_balance_updated.emit(skr_balance)
		return

	# 1. Fetch via SolanaService inspector
	var solana_service = get_node_or_null("/root/SolanaService")
	if solana_service and solana_service.has_node("AccountInspector"):
		var inspector = solana_service.get_node("AccountInspector")
		if inspector and inspector.has_method("get_account_balance"):
			if not inspector.on_balance_loaded.is_connected(_on_balance_loaded):
				inspector.on_balance_loaded.connect(_on_balance_loaded)
			inspector.get_account_balance(connected_pubkey)

	# 2. Also direct JSON-RPC query to Devnet for guaranteed real balance
	_query_devnet_sol_balance(connected_pubkey)
	fetch_skr_balance()


func _query_devnet_sol_balance(pubkey: String) -> void:
	var http := HTTPRequest.new()
	http.timeout = 6.0
	add_child(http)
	var payload := {
		"jsonrpc": "2.0",
		"id": 1,
		"method": "getBalance",
		"params": [pubkey, {"commitment": "confirmed"}]
	}
	http.request_completed.connect(func(res: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		if res == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("result"):
					var val = data["result"].get("value", 0)
					sol_balance = float(val) / 1_000_000_000.0
					_save_session()
					balance_updated.emit(sol_balance)
					print("[GlobalState] Direct Devnet SOL balance: %.4f" % sol_balance)
		http.queue_free()
	)
	var headers := PackedStringArray(["Content-Type: application/json"])
	http.request("https://api.devnet.solana.com", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))


func fetch_skr_balance() -> void:
	if not is_connected or connected_pubkey.is_empty():
		return
	if wallet_provider_id == 999:
		skr_balance = 0.0
		skr_balance_updated.emit(skr_balance)
		return

	# Query SPL token accounts on Devnet for real balance
	var http := HTTPRequest.new()
	http.timeout = 6.0
	add_child(http)
	var payload := {
		"jsonrpc": "2.0",
		"id": 2,
		"method": "getTokenAccountsByOwner",
		"params": [
			connected_pubkey,
			{"programId": "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"},
			{"encoding": "jsonParsed"}
		]
	}
	http.request_completed.connect(func(res: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		var total_tokens := 0.0
		if res == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("result"):
					var accounts = data["result"].get("value", [])
					for acc in accounts:
						var info = acc.get("account", {}).get("data", {}).get("parsed", {}).get("info", {})
						var amount_info = info.get("tokenAmount", {})
						total_tokens += float(amount_info.get("uiAmount", 0.0))
		skr_balance = total_tokens
		_save_session()
		skr_balance_updated.emit(skr_balance)
		print("[GlobalState] Direct Devnet SKR balance: %.2f" % skr_balance)
		http.queue_free()
	)
	var headers := PackedStringArray(["Content-Type: application/json"])
	http.request("https://api.devnet.solana.com", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))


func _on_balance_loaded(balance_lamports: int) -> void:
	sol_balance = float(balance_lamports) / 1_000_000_000.0
	print("[GlobalState] Updated SOL Balance via inspector: ", sol_balance)
	_save_session()
	balance_updated.emit(sol_balance)


## Helper to convert a Pubkey object or string to clean base58 string
func _extract_pubkey_string(key_obj: Variant) -> String:
	if key_obj == null:
		return ""
	if key_obj is String:
		return key_obj
	if key_obj.has_method("to_string"):
		var s: String = key_obj.to_string()
		if not s.is_empty() and s != "[Pubkey:]":
			return s
	var raw_str := str(key_obj)
	if raw_str.begins_with("[Pubkey:") and raw_str.ends_with("]"):
		return raw_str.substr(8, raw_str.length() - 9)
	return raw_str


## Helper to truncate pubkey for UI display (e.g. 7etj...Fm3w)
func get_shorthand(key: String) -> String:
	if key.length() <= 8:
		return key
	return key.substr(0, 4) + "..." + key.substr(key.length() - 4, 4)
