extends WorldEnvironment
# Runs the game: places everything, counts coins, times the run, ends the game.

# --- Settings you can tweak in the Inspector ---
@export var coin_scene: PackedScene       # drag Coin.tscn here
@export var enemy_scene: PackedScene      # drag Enemy.tscn here
@export var coin_count = 25                # how many coins to place
@export var coin_spacing = 5.0             # minimum distance between coins
@export var enemy_count = 6                # how many enemies to place
@export var enemy_min_distance = 18.0      # enemies spawn at least this far from the player
@export var menu_scene = "res://scenes/menu/Menu.tscn" # (String, FILE, "*.tscn")

# --- Shortcuts to the other nodes ---
@onready var maze = $GridMap
@onready var player = $Player
@onready var coin_label = $HUD/CoinLabel
@onready var time_label = $HUD/TimeLabel
@onready var end_panel = $HUD/EndPanel
@onready var message = $HUD/EndPanel/VBoxContainer/Message
@onready var restart_button = $HUD/EndPanel/VBoxContainer/ButtonContainer/RestartButton
@onready var menu_button = $HUD/EndPanel/VBoxContainer/ButtonContainer/MenuButton

# --- Variables ---
var coins_total = 0
var coins_left = 0
var game_over = false
var time_elapsed = 0.0     # seconds the player has spent in this run


func _ready():
	# The HUD must keep working while the game is paused, or the buttons won't click.
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	end_panel.visible = false

	# Put the player in the starting room.
	player.global_transform.origin = maze.get_start_position()
	player.connect("died", Callable(self, "_on_player_died"))
	var start = player.global_transform.origin

	_spawn_enemies(start)
	_spawn_coins(start)
	_update_label()

	restart_button.connect("pressed", Callable(self, "_on_restart"))
	menu_button.connect("pressed", Callable(self, "_on_menu"))


func _process(delta):
	# Runs every frame. Count up the time until the game ends.
	# (This also stops by itself while the game is paused.)
	if not game_over:
		time_elapsed += delta
		time_label.text = _format_time_precise(time_elapsed)


func _format_time_precise(t: float) -> String:
	# Turns seconds into "mm:ss.cc" (centiseconds), e.g. 75.34 -> "01:15.34"
	var total_sec = int(t)
	var minutes = int(total_sec / 60)
	var seconds = total_sec % 60
	var centiseconds = int((t - total_sec) * 100.0)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]


func _spawn_enemies(start):
	# Pick spread-out floor spots, far from the player.
	var spots = maze.pick_floor_positions(enemy_count, start, enemy_min_distance, 8.0)
	for pos in spots:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_transform.origin = pos + Vector3(0, 1.0, 0)


func _spawn_coins(start):
	# Pick spread-out floor spots anywhere except right on top of the player.
	var spots = maze.pick_floor_positions(coin_count, start, 4.0, coin_spacing)
	for pos in spots:
		var coin = coin_scene.instantiate()
		add_child(coin)
		coin.global_transform.origin = pos + Vector3(0, 0.8, 0)
		coin.connect("collected", Callable(self, "_on_coin_collected"))
	coins_total = spots.size()
	coins_left = spots.size()
	if spots.size() < coin_count:
		print("Only room for ", spots.size(), " coins. Lower Coin Spacing to fit more.")


func _on_coin_collected():
	coins_left -= 1
	_update_label()
	if coins_left <= 0:
		_end_game(true)    # all coins collected: win!


func _on_player_died():
	_end_game(false)       # caught: lose


func _update_label():
	coin_label.text = "Coins: %d / %d" % [coins_total - coins_left, coins_total]


func _end_game(won: bool):
	if game_over:
		return             # only end once
	game_over = true

	message.text = ("YOU WIN!" if won else "CAUGHT!") + "\nTime: " + _format_time_precise(time_elapsed)
	end_panel.visible = true
	get_tree().paused = true    # freeze the game behind the panel


func _on_restart():
	get_tree().paused = false   # always unpause before changing scenes
	get_tree().reload_current_scene()


func _on_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene)
