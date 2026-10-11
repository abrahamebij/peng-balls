extends Node
class_name PoolDataService

## PoolDataService — Provides pool data and leaderboard entries.
## Currently provides realistic sample data tailored to the connected wallet,
## designed to be easily swapped with on-chain Solana Anchor queries.

static var sample_pools: Array[Dictionary] = [
	{
		"round_id": 1,
		"name": "Weekly Sprint Pool",
		"token_type": "Devnet SOL",
		"token_symbol": "SOL",
		"stake": "0.05 SOL",
		"entry_fee_lamports": 50_000_000,
		"total_pot": "14.25 SOL",
		"winner_cut": "12.82 SOL (90%)",
		"total_runs": 285,
		"time_left": "3d 14h",
		"current_leader": "DeV1...1111",
		"best_time": "00:28.95",
		"status": "Active"
	},
	{
		"round_id": 2,
		"name": "High Roller Pool",
		"token_type": "Devnet SOL",
		"token_symbol": "SOL",
		"stake": "0.50 SOL",
		"entry_fee_lamports": 500_000_000,
		"total_pot": "32.00 SOL",
		"winner_cut": "28.80 SOL (90%)",
		"total_runs": 64,
		"time_left": "5d 08h",
		"current_leader": "7etj...4bZ9",
		"best_time": "00:27.40",
		"status": "Active"
	},
	{
		"round_id": 3,
		"name": "Clock-In Arcade Pool",
		"token_type": "$SKR Token",
		"token_symbol": "SKR",
		"stake": "100 SKR",
		"entry_fee_lamports": 100_000_000,
		"total_pot": "25,400 SKR",
		"winner_cut": "22,860 SKR (90%)",
		"total_runs": 254,
		"time_left": "2d 04h",
		"current_leader": "9pLm...8kE2",
		"best_time": "00:31.10",
		"status": "Active"
	}
]


## Returns the top 50 standings for a given round, guaranteeing the user's address is present
static func get_top_50_standings(round_id: int, user_pubkey: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var base_time_ms := 28500 + (round_id * 350)
	
	# Sample competitor addresses
	var sample_addresses := [
		"7etjW1uPretendDevWalletX8c4BvQ9r3M12345678",
		"9pLmK8rVq2TsYz1W4eRtYuIoPaSdFgHjKlZxCvBnMq",
		"4xQrVn19LmKp88ZtYuIoPaSdFgHjKlZxCvBnMqWeRt",
		"Bw7Z3mP4Lk99Mn22Po00Qq11Rr33Ss44Tt55Uu66Vv",
		"6yTuKp88Qw12Er34Ty56Ui78Op90As12Df34Gh56Jk",
		"2mNtR9w1ZxCvBnMqWeRtYuIoPaSdFgHjKlZxCvBn11",
		"8vBxLq44Po99Oi88Uu77Yy66Tt55Rr44Ee33Ww22Qq",
		"5cDsP1z0MnBvCxZlKjHgFdSaQwErTyUiOpLkJhGf12",
		"3kLmWw77AsDfGhJkLzXcCvBnMqWeRtYuIoPaSdFg33",
		"1jKhTy99QazWsxEdcRfvTgbYhnUjmIkoLpQazWsx44",
		"C9mKx129VbNmMkLpOiUyTrEwQaZsXkCdEfGhIjKl55",
		"D8nLy230WcOnNlMqPjVzUsFxRbAtYlDeFgHiJkLm66",
		"E7oMz341XdPoOmNrQkAwVtGyScBuZmEfGhIjKlMn77",
		"F6pNa452YeQpPnOsRlBxWuHzTdCvAnFgHiJkLmNo88",
		"G5qOb563ZfRqQoPtSmCyXvIaUeDwBoGhIjKlMnOp99"
	]
	
	# Player is placed around rank 1 in pool #1, rank 3 in pool #2, and rank 7 in pool #3
	var player_target_rank := 1 if round_id == 1 else (3 if round_id == 2 else 7)
	if user_pubkey.is_empty():
		user_pubkey = "DeV1LapToPpReTeNdWaLLeT111111111111111111111"
	
	var addr_idx := 0
	for rank in range(1, 51):
		var is_player := (rank == player_target_rank)
		var addr: String
		if is_player:
			addr = user_pubkey
		else:
			if addr_idx < sample_addresses.size():
				addr = sample_addresses[addr_idx]
				addr_idx += 1
			else:
				# Generate consistent synthetic address
				addr = "Sol%02d" % rank + "RandomPlayer" + str(rank * 1337) + "WalletAddressKey11"
		
		# Time increments down the leaderboard
		var entry_time_ms: int = base_time_ms + (rank - 1) * int(randf_range(400, 950))
		if is_player:
			entry_time_ms = base_time_ms + (rank - 1) * 450
		
		# Realistic win/loss stats
		var wins: int = maxi(1, 26 - int(rank * 0.45) + (3 if is_player else 0))
		var losses: int = maxi(1, int(rank * 0.35) + (2 if is_player else 1))
		
		entries.append({
			"rank": rank,
			"player_pubkey": addr,
			"shorthand": get_shorthand(addr),
			"time_ms": entry_time_ms,
			"formatted_time": format_time(entry_time_ms),
			"wins": wins,
			"losses": losses,
			"is_player": is_player
		})
	
	return entries


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
