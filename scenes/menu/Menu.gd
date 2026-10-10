extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var multiplayer_button = $VBoxContainer/MultiPlayerButton
@onready var credits_button = $VBoxContainer/CreditsButton
@onready var account_info_button = get_node_or_null("AccountInfo")


func _ready():
	start_button.pressed.connect(_on_start)
	if multiplayer_button:
		multiplayer_button.pressed.connect(_on_multiplayer)
	if credits_button:
		credits_button.pressed.connect(_on_credits)
	if account_info_button:
		account_info_button.pressed.connect(_on_account_info)


func _on_start():
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")


func _on_multiplayer():
	print("Multiplayer is not ready yet")


func _on_credits():
	print("Credits is not ready yet")


func _on_account_info():
	get_tree().change_scene_to_file("res://scenes/menu/ConnectWallet.tscn")

