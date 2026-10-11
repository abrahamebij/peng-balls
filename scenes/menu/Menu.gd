extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var how_to_play_button = get_node_or_null("VBoxContainer/HowToPlayButton")
@onready var credits_button = get_node_or_null("VBoxContainer/CreditsButton")
@onready var account_info_button = get_node_or_null("AccountInfo")


func _ready():
	# Enforce authentication: no unauthenticated user should access the menu or game
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if not gs.is_connected:
			get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")
			return

	start_button.pressed.connect(_on_start)
	if how_to_play_button:
		how_to_play_button.pressed.connect(_on_how_to_play)
	if credits_button:
		credits_button.pressed.connect(_on_credits)
	if account_info_button:
		account_info_button.pressed.connect(_on_account_info)


func _on_start():
	if ResourceLoader.exists("res://scenes/menu/LoadingScreen.tscn"):
		if has_node("/root/GlobalState"):
			get_node("/root/GlobalState").next_scene_path = "res://scenes/game/Game.tscn"
		get_tree().change_scene_to_file("res://scenes/menu/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


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
