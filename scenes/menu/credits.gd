extends Control

@onready var back_btn: Button = get_node_or_null("BackBtn")


func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_go_back)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	if ResourceLoader.exists("res://scenes/menu/Menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu/Menu.tscn")
