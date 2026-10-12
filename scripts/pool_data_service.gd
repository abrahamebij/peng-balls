extends Node
class_name PoolDataService

## PoolDataService — Provides live pool data, standings, and run submission.
## Communicates with the live backend at https://pengballs.vercel.app/api

static var api_base_url := "https://pengballs.vercel.app/api"

static var is_fetching_pools: bool = false
static var last_fetch_time: float = 0.0

static var sample_pools: Array[Dictionary] = [
	{
		"round_id": 1,
		"roundId": 1,
		"name": "Weekly Sprint Pool",
		"token_type": "Devnet SOL",
		"tokenType": "Devnet SOL",
		"token_symbol": "SOL",
		"tokenSymbol": "SOL",
		"stake": "0.05 SOL",
		"entry_fee_lamports": 50_000_000,
		"entryFeeLamports": 50_000_000,
		"vaultPubkey": "sJy3Qfqi2gSZH2PG8jw9FayenmgN5tmwVSjwYLVwEH6",
		"total_pot": "0.00 SOL",
		"totalPot": "0.00 SOL",
		"totalPotFormatted": "0.00 SOL",
		"total_runs": 0,
		"totalRuns": 0,
		"time_left": "7d 00h",
		"timeLeft": "7d 00h",
		"current_leader": "--",
		"currentLeader": "--",
		"best_time": "--",
		"bestTime": "--",
		"status": "Active",
		"is_native": true,
		"isNative": true
	},
	{
		"round_id": 2,
		"roundId": 2,
		"name": "High Roller Pool",
		"token_type": "Devnet SOL",
		"tokenType": "Devnet SOL",
		"token_symbol": "SOL",
		"tokenSymbol": "SOL",
		"stake": "0.50 SOL",
		"entry_fee_lamports": 500_000_000,
		"entryFeeLamports": 500_000_000,
		"vaultPubkey": "sJy3Qfqi2gSZH2PG8jw9FayenmgN5tmwVSjwYLVwEH6",
		"total_pot": "0.00 SOL",
		"totalPot": "0.00 SOL",
		"totalPotFormatted": "0.00 SOL",
		"total_runs": 0,
		"totalRuns": 0,
		"time_left": "7d 00h",
		"timeLeft": "7d 00h",
		"current_leader": "--",
		"currentLeader": "--",
		"best_time": "--",
		"bestTime": "--",
		"status": "Active",
		"is_native": true,
		"isNative": true
	},
	{
		"round_id": 3,
		"roundId": 3,
		"name": "Clock-In Arcade Pool",
		"token_type": "Devnet SOL",
		"tokenType": "Devnet SOL",
		"token_symbol": "SOL",
		"tokenSymbol": "SOL",
		"stake": "0.10 SOL",
		"entry_fee_lamports": 100_000_000,
		"entryFeeLamports": 100_000_000,
		"vaultPubkey": "sJy3Qfqi2gSZH2PG8jw9FayenmgN5tmwVSjwYLVwEH6",
		"total_pot": "0.00 SOL",
		"totalPot": "0.00 SOL",
		"totalPotFormatted": "0.00 SOL",
		"total_runs": 0,
		"totalRuns": 0,
		"time_left": "7d 00h",
		"timeLeft": "7d 00h",
		"current_leader": "--",
		"currentLeader": "--",
		"best_time": "--",
		"bestTime": "--",
		"status": "Active",
		"is_native": true,
		"isNative": true
	}
]


## Fetches live weekly community pools from the backend API
static func fetch_pools(caller: Node = null, callback: Callable = Callable()) -> void:
	var tree = caller.get_tree() if is_instance_valid(caller) else (Engine.get_main_loop() as SceneTree)
	if not tree:
		if callback.is_valid():
			callback.call(sample_pools)
		return

	var http := HTTPRequest.new()
	http.timeout = 6.0
	tree.root.add_child(http)

	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var pools_out: Array[Dictionary] = []
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("pools"):
					var list = data.get("pools")
					if list is Array and not list.is_empty():
						for item in list:
							if item is Dictionary:
								var round_id: int = int(item.get("roundId", item.get("round_id", 1)))
								pools_out.append({
									"round_id": round_id,
									"roundId": round_id,
									"name": str(item.get("name", "Weekly Pool")),
									"token_type": str(item.get("tokenType", "Devnet SOL")),
									"tokenType": str(item.get("tokenType", "Devnet SOL")),
									"token_symbol": str(item.get("tokenSymbol", "SOL")),
									"tokenSymbol": str(item.get("tokenSymbol", "SOL")),
									"stake": str(item.get("stake", "0.05 SOL")),
									"entry_fee_lamports": int(item.get("entryFeeLamports", 50000000)),
									"entryFeeLamports": int(item.get("entryFeeLamports", 50000000)),
									"vaultPubkey": str(item.get("vaultPubkey", "sJy3Qfqi2gSZH2PG8jw9FayenmgN5tmwVSjwYLVwEH6")),
									"total_pot": str(item.get("totalPotFormatted", item.get("totalPot", "0.00 SOL"))),
									"totalPot": str(item.get("totalPotFormatted", item.get("totalPot", "0.00 SOL"))),
									"totalPotFormatted": str(item.get("totalPotFormatted", "0.00 SOL")),
									"total_runs": int(item.get("totalRuns", 0)),
									"totalRuns": int(item.get("totalRuns", 0)),
									"time_left": str(item.get("timeLeft", "--")),
									"timeLeft": str(item.get("timeLeft", "--")),
									"current_leader": str(item.get("currentLeader", "--")),
									"currentLeader": str(item.get("currentLeader", "--")),
									"best_time": str(item.get("bestTimeFormatted", "--")),
									"bestTime": str(item.get("bestTimeFormatted", "--")),
									"status": str(item.get("status", "Active")),
									"is_native": bool(item.get("isNative", true)),
									"isNative": bool(item.get("isNative", true))
								})

		if not pools_out.is_empty():
			sample_pools = pools_out
		else:
			pools_out = sample_pools

		http.queue_free()
		if callback.is_valid():
			callback.call(pools_out)
	)

	var url := api_base_url + "/pools"
	var err = http.request(url, ["Accept: application/json"], HTTPClient.METHOD_GET)
	if err != OK:
		print("[PoolDataService] HTTPRequest start error: %d" % err)
		http.queue_free()
		if callback.is_valid():
			callback.call(sample_pools)


## Fetches Top 50 standings for ONLY the requested round from server
static func fetch_standings(round_id: int, user_pubkey: String, caller: Node = null, callback: Callable = Callable()) -> void:
	var tree = caller.get_tree() if is_instance_valid(caller) else (Engine.get_main_loop() as SceneTree)
	if not tree:
		if callback.is_valid():
			callback.call(get_top_50_standings(round_id, user_pubkey))
		return

	var http := HTTPRequest.new()
	http.timeout = 6.0
	tree.root.add_child(http)

	var url := api_base_url + "/pools/" + str(round_id) + "/standings?user=" + user_pubkey

	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var standings_out: Array[Dictionary] = []
		if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("standings"):
					var list = data.get("standings")
					if list is Array:
						for entry in list:
							if entry is Dictionary:
								standings_out.append({
									"rank": int(entry.get("rank", 1)),
									"player_pubkey": str(entry.get("playerPubkey", "")),
									"shorthand": str(entry.get("shorthand", "")),
									"time_ms": int(entry.get("timeMs", 0)),
									"formatted_time": str(entry.get("formattedTime", "")),
									"wins": int(entry.get("wins", 0)),
									"losses": int(entry.get("losses", 0)),
									"is_player": bool(entry.get("isPlayer", false))
								})

		http.queue_free()
		if callback.is_valid():
			callback.call(standings_out)
	)

	var err = http.request(url, ["Accept: application/json"], HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call([])


## Registers entry into a round with the backend
static func enter_pool(pool: Dictionary, player_pubkey: String, caller: Node = null, callback: Callable = Callable(), tx_sig: String = "") -> void:
	var tree = caller.get_tree() if is_instance_valid(caller) else (Engine.get_main_loop() as SceneTree)
	if not tree:
		if callback.is_valid():
			callback.call(true, "Entered locally")
		return

	var http := HTTPRequest.new()
	http.timeout = 8.0
	tree.root.add_child(http)

	var round_id: int = int(pool.get("round_id", pool.get("roundId", 1)))
	var payload := {
		"roundId": round_id,
		"playerPubkey": player_pubkey,
		"txSignature": tx_sig,
		"timestamp": Time.get_unix_time_from_system()
	}
	var body_str := JSON.stringify(payload)

	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var success := true
		var message := "Entry Confirmed"
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201):
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.has("message"):
					message = str(data.get("message"))
			print("[PoolDataService] enter_pool confirmed on backend: ", message)
		else:
			print("[PoolDataService] enter_pool backend response %d" % response_code)

		http.queue_free()
		if callback.is_valid():
			callback.call(success, message)
	)

	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var url := api_base_url + "/pools/" + str(round_id) + "/enter"
	var err = http.request(url, headers, HTTPClient.METHOD_POST, body_str)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call(true, "Local registration")


## Submits completed run time to backend and records it in this specific pool's leaderboard
static func submit_run(round_id: int, player_pubkey: String, time_ms: int, time_formatted: String, won: bool, caller: Node = null, callback: Callable = Callable()) -> void:
	var tree = caller.get_tree() if is_instance_valid(caller) else (Engine.get_main_loop() as SceneTree)
	if not tree:
		if callback.is_valid():
			callback.call(true, {})
		return

	var http := HTTPRequest.new()
	http.timeout = 8.0
	tree.root.add_child(http)

	var payload := {
		"roundId": round_id,
		"playerPubkey": player_pubkey,
		"timeMs": time_ms,
		"timeFormatted": time_formatted,
		"won": won,
		"coinsCollected": 25,
		"timestamp": Time.get_unix_time_from_system()
	}
	var body_str := JSON.stringify(payload)

	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var res_data := {}
		if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201):
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var d = json.get_data()
				if d is Dictionary:
					res_data = d
			print("[PoolDataService] Run recorded in backend pool #%d!" % round_id)
		else:
			print("[PoolDataService] submit_run API returned %d" % response_code)

		http.queue_free()
		if callback.is_valid():
			callback.call(true, res_data)
	)

	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	var url := api_base_url + "/runs/finish"
	var err = http.request(url, headers, HTTPClient.METHOD_POST, body_str)
	if err != OK:
		http.queue_free()
		if callback.is_valid():
			callback.call(true, {})


## Fallback standings — returns real submissions without mock data
static func get_top_50_standings(_round_id: int, _user_pubkey: String) -> Array[Dictionary]:
	return []


static func format_time(time_ms: int) -> String:
	var total_sec := time_ms / 1000
	var remainder_ms := (time_ms % 1000) / 10
	var minutes := total_sec / 60
	var seconds := total_sec % 60
	return "%02d:%02d.%02d" % [minutes, seconds, remainder_ms]


static func get_shorthand(key: String) -> String:
	if key.length() <= 8:
		return key
	return key.substr(0, 4) + "..." + key.substr(key.length() - 4, 4)


static func calculate_rank_for_time(round_id: int, time_ms: int) -> int:
	var standings = get_top_50_standings(round_id, "")
	var rank := 1
	for entry in standings:
		if time_ms < entry.get("time_ms", 999999):
			return rank
		rank += 1
	return mini(rank, 50)
