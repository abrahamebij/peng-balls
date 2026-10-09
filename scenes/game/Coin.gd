extends Area3D
# A spinning coin. When the player touches it, it tells the Level and vanishes.

# Fires when the player picks this coin up.
signal collected


func _ready():
	# Ask Godot to tell us when a body enters this area.
	connect("body_entered", Callable(self, "_on_body_entered"))


func _process(delta):
	# Spin around the up axis, 3 radians per second.
	rotate_y(delta * 3.0)


func _on_body_entered(body):
	# Only the player can collect coins (enemies are ignored).
	if body.is_in_group("player"):
		set_deferred("monitoring", false)   # stop detecting, so it can't count twice
		emit_signal("collected")
		queue_free()                        # remove the coin
