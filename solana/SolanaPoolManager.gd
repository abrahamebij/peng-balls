extends Node
# SolanaPoolManager.gd
# Handles Solana Devnet Prize Pool, $SKR / DevCoin integration, MWA wallet connection, run recording, and Leaderboard.

signal wallet_connected(address: String)
signal wallet_disconnected
signal run_recorded(is_win: bool, time_ms: int, rank: int)
signal pool_updated(total_pot: float, best_time_str: String)
signal currency_switched(currency_name: String)

const PROGRAM_ID = "Mh2yn8cR99LYd88UcihsCnbXatss89VKxYZU9W6WQEj"
const DEVNET_RPC = "https://api.devnet.solana.com"

# Official / Devnet Mint identifiers
const SKR_MINT_DEVNET = "SKRmb11111111111111111111111111111111111111" # Solana Mobile SKR
const DEVCOIN_MINT_DEVNET = "DevCoin11111111111111111111111111111111111"

enum Currency { SKR, DEVCOIN }
var current_currency: Currency = Currency.SKR

# Pool parameters per currency
var round_id: int = 1
var entry_fee_skr: float = 250.0       # 250 $SKR per run
var entry_fee_devcoin: float = 100.0   # 100 DevCoin per run
var total_pot_skr: float = 0.0
var total_pot_devcoin: float = 0.0

var best_time_ms: int = 0
var current_winner: String = ""
var round_time_remaining: int = 0

# Player state
var wallet_address: String = ""
var is_connected: bool = false
var balance_skr: float = 0.0
var balance_devcoin: float = 0.0

var player_runs: int = 0
var player_wins: int = 0
var player_losses: int = 0
var player_best_time_ms: int = 0

# Native Mobile Wallet Adapter plugin singleton (if compiled into APK)
var mwa_plugin = null

# Live Leaderboard (sorted lowest time first)
var leaderboard: Array = []


func _ready():
	_init_mwa()
	_load_saved_data()


func _init_mwa():
	# Check for Android Mobile Wallet Adapter native plugin
	if Engine.has_singleton("SolanaMobileWalletAdapter"):
		mwa_plugin = Engine.get_singleton("SolanaMobileWalletAdapter")
		print("[MWA] Native Solana Mobile Wallet Adapter plugin detected!")
	else:
		print("[MWA] Native plugin not detected. Using Mobile DeepLink / Devnet Simulator.")


func set_currency(new_currency: Currency):
	current_currency = new_currency
	var c_name = "$SKR" if current_currency == Currency.SKR else "DevCoin"
	currency_switched.emit(c_name)
	pool_updated.emit(get_active_pot(), get_formatted_time(best_time_ms))


func get_active_currency_name() -> String:
	return "$SKR" if current_currency == Currency.SKR else "DevCoin"


func get_active_entry_fee() -> float:
	return entry_fee_skr if current_currency == Currency.SKR else entry_fee_devcoin


func get_active_pot() -> float:
	return total_pot_skr if current_currency == Currency.SKR else total_pot_devcoin


func get_active_balance() -> float:
	return balance_skr if current_currency == Currency.SKR else balance_devcoin


func connect_wallet(address: String = ""):
	# 1. Native Mobile Wallet Adapter call (Android APK)
	if mwa_plugin != null and mwa_plugin.has_method("connect"):
		print("[MWA] Calling native MWA connect()...")
		mwa_plugin.connect()
		return

	# 2. Android Intent / Deep link fallback
	if OS.get_name() == "Android" and address == "":
		var mwa_intent_uri = "solana-wallet://v1/authorize?cluster=devnet&identity_name=PengBalls"
		OS.shell_open(mwa_intent_uri)
	elif address != "":
		wallet_address = address
		is_connected = true
		wallet_connected.emit(wallet_address)
		fetch_devnet_balance()


func disconnect_wallet():
	if mwa_plugin != null and mwa_plugin.has_method("disconnect"):
		mwa_plugin.disconnect()
	wallet_address = ""
	is_connected = false
	wallet_disconnected.emit()


func enter_pool_run() -> bool:
	if not is_connected:
		connect_wallet()

	var fee = get_active_entry_fee()
	var bal = get_active_balance()

	if bal < fee:
		print("Insufficient balance to enter pool!")
		return false

	if current_currency == Currency.SKR:
		balance_skr -= fee
		total_pot_skr += fee
	else:
		balance_devcoin -= fee
		total_pot_devcoin += fee

	player_runs += 1
	_save_data()
	pool_updated.emit(get_active_pot(), get_formatted_time(best_time_ms))
	return true


func record_run_result(is_win: bool, elapsed_seconds: float):
	var time_ms = int(elapsed_seconds * 1000.0)

	if is_win:
		player_wins += 1
		if player_best_time_ms == 0 or time_ms < player_best_time_ms:
			player_best_time_ms = time_ms

		if best_time_ms == 0 or time_ms < best_time_ms:
			best_time_ms = time_ms
			current_winner = wallet_address if is_connected else "Player (You)"

		_insert_leaderboard_entry(wallet_address if is_connected else "Player (You)", time_ms)
	else:
		player_losses += 1

	_save_data()
	run_recorded.emit(is_win, time_ms, get_player_rank())
	pool_updated.emit(get_active_pot(), get_formatted_time(best_time_ms))


func _insert_leaderboard_entry(player_name: String, time_ms: int):
	var new_entry = {
		"rank": 0,
		"player": player_name,
		"time_ms": time_ms,
		"time_str": get_formatted_time(time_ms),
		"date": "Today",
		"currency": get_active_currency_name()
	}
	leaderboard.append(new_entry)
	leaderboard.sort_custom(Callable(self, "_compare_times"))
	if leaderboard.size() > 10:
		leaderboard.resize(10)

	for i in range(leaderboard.size()):
		leaderboard[i]["rank"] = i + 1


func _compare_times(a, b) -> bool:
	return a["time_ms"] < b["time_ms"]


func get_player_rank() -> int:
	for entry in leaderboard:
		if entry["time_ms"] == player_best_time_ms:
			return entry["rank"]
	return -1


func get_formatted_time(ms: int) -> String:
	var total_sec = ms / 1000
	var rem_ms = (ms % 1000) / 10
	var minutes = total_sec / 60
	var seconds = total_sec % 60
	return "%02d:%02d.%02d" % [minutes, seconds, rem_ms]


func _load_saved_data():
	var file = FileAccess.open("user://solana_player_stats.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				player_runs = data.get("runs", 0)
				player_wins = data.get("wins", 0)
				player_losses = data.get("losses", 0)
				player_best_time_ms = data.get("best_time_ms", 0)
				wallet_address = data.get("wallet_address", "")
				if wallet_address != "":
					is_connected = true
					fetch_devnet_balance()

	var lb_file = FileAccess.open("user://leaderboard.json", FileAccess.READ)
	if lb_file:
		var lb_json = JSON.new()
		if lb_json.parse(lb_file.get_as_text()) == OK:
			var lb_data = lb_json.get_data()
			if lb_data is Array:
				leaderboard = lb_data
				if leaderboard.size() > 0:
					best_time_ms = leaderboard[0].get("time_ms", 0)
					current_winner = leaderboard[0].get("player", "")


func _save_data():
	var file = FileAccess.open("user://solana_player_stats.json", FileAccess.WRITE)
	if file:
		var data = {
			"runs": player_runs,
			"wins": player_wins,
			"losses": player_losses,
			"best_time_ms": player_best_time_ms,
			"wallet_address": wallet_address
		}
		file.store_string(JSON.stringify(data))

	var lb_file = FileAccess.open("user://leaderboard.json", FileAccess.WRITE)
	if lb_file:
		lb_file.store_string(JSON.stringify(leaderboard))


func fetch_devnet_balance():
	if wallet_address == "":
		return
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, response_code, _headers, body):
		http.queue_free()
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var res = json.get_data()
				if res is Dictionary and res.has("result"):
					var lamports = res["result"].get("value", 0)
					balance_skr = float(lamports) / 1000000000.0
					balance_devcoin = balance_skr
					pool_updated.emit(get_active_pot(), get_formatted_time(best_time_ms))
	)
	var payload = JSON.stringify({
		"jsonrpc": "2.0",
		"id": 1,
		"method": "getBalance",
		"params": [wallet_address]
	})
	http.request(DEVNET_RPC, ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
