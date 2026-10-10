extends Control

@export var target_scene: String = "res://scenes/game/Game.tscn"
@export var min_duration: float = 2.5

@onready var label: Label = $Label

var timer: float = 0.0
const CYCLE_DURATION: float = 2.5

var _resolved_target: String = ""
var _is_loading: bool = false
var _transitioned: bool = false


func _ready() -> void:
	_update_dots(0.0)

	_resolved_target = target_scene
	if has_node("/root/GlobalState"):
		var gs = get_node("/root/GlobalState")
		if gs.get("next_scene_path") and not str(gs.next_scene_path).is_empty():
			_resolved_target = gs.next_scene_path
			gs.next_scene_path = ""

	if not _resolved_target.is_empty() and ResourceLoader.exists(_resolved_target):
		var err = ResourceLoader.load_threaded_request(_resolved_target)
		if err == OK:
			_is_loading = true
		else:
			push_error("[LoadingScreen] Threaded load request failed with error: %d" % err)
	else:
		push_warning("[LoadingScreen] Target scene not found: %s" % _resolved_target)


func _process(delta: float) -> void:
	timer += delta
	var cycle_time: float = fmod(timer, CYCLE_DURATION)
	_update_dots(cycle_time)

	if _transitioned:
		return

	if _is_loading:
		var status = ResourceLoader.load_threaded_get_status(_resolved_target)
		if status == ResourceLoader.THREAD_LOAD_LOADED and timer >= min_duration:
			_transitioned = true
			var loaded_res = ResourceLoader.load_threaded_get(_resolved_target)
			if loaded_res is PackedScene:
				get_tree().change_scene_to_packed(loaded_res)
			else:
				get_tree().change_scene_to_file(_resolved_target)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("[LoadingScreen] Failed to load target scene: %s" % _resolved_target)
			_is_loading = false
	elif timer >= min_duration and not _resolved_target.is_empty():
		_transitioned = true
		get_tree().change_scene_to_file(_resolved_target)


func _update_dots(t: float) -> void:
	# Timeline:
	# 0.0s - 1.0s (including first 0.5s): no dots
	# 1.0s - 1.5s: first dot appears
	# 1.5s - 2.0s: second dot appears
	# 2.0s - 2.5s: third dot appears
	# at 2.5s: resets to 0.0s (all dots disappear) and loops
	if t < 1.0:
		label.text = "Loading"
	elif t < 1.5:
		label.text = "Loading."
	elif t < 2.0:
		label.text = "Loading.."
	else:
		label.text = "Loading..."
