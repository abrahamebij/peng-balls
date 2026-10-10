extends Control

@onready var label: Label = $Label

var timer: float = 0.0
const CYCLE_DURATION: float = 2.5


func _ready() -> void:
	_update_dots(0.0)


func _process(delta: float) -> void:
	timer += delta
	var cycle_time: float = fmod(timer, CYCLE_DURATION)
	_update_dots(cycle_time)


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
