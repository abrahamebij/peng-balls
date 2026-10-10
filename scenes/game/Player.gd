extends CharacterBody3D
# The rolling ball the player controls.

# Fires when an enemy catches the player. Game.gd listens for this.
signal died

# --- Settings you can tweak in the Inspector ---
@export var speed = 10.0        # top speed, in units per second
@export var accel = 12.0        # how quickly the ball speeds up and slows down
@export var gravity = 30.0      # pull downward. Without this the ball floats!
@export var ball_radius = 0.5   # half the width of the ball mesh (for rolling)

# --- Variables ---
var dead = false               # true once caught, so we only die once

# The touch controls (joystick). We find them automatically in get_input_vector().
# THIS is the line that was missing and caused your error.
var controls = null

# --- Shortcuts to child nodes ---
@onready var cam_pivot = get_node_or_null("CameraPivot")
@onready var mesh = $MeshInstance3D


func _ready():
	# Lets enemies find the player by looking in this group.
	add_to_group("player")


func get_input_vector():
	# Returns which way the player wants to go as a Vector2:
	#   x = left (-1) / right (+1),  y = up (-1) / down (+1)

	# If we haven't been given the touch controls yet, go and find them.
	if controls == null:
		var found = get_tree().get_nodes_in_group("touch_controls")
		if found.size() > 0:
			controls = found[0]

	# 1. Ask the joystick first. If it's being pushed, use it.
	if controls != null:
		var stick = controls.get_move_vector()
		if stick.length() > 0.0:
			return stick

	# 2. Keyboard arrows and WASD keys (for testing on PC).
	var kb = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
	if kb.length() == 0.0:
		if Input.is_key_pressed(KEY_W): kb.y -= 1.0
		if Input.is_key_pressed(KEY_S): kb.y += 1.0
		if Input.is_key_pressed(KEY_A): kb.x -= 1.0
		if Input.is_key_pressed(KEY_D): kb.x += 1.0
	return kb


func _physics_process(delta):
	# 1. Which way is the camera facing? Movement is relative to it.
	var cam_forward = Vector3.FORWARD
	var cam_right = Vector3.RIGHT
	if cam_pivot:
		cam_forward = -cam_pivot.global_transform.basis.z
		cam_right = cam_pivot.global_transform.basis.x
	cam_forward.y = 0                       # flatten, so looking down doesn't slow us
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	# 2. Turn the input into a world direction.
	# Joystick up is a negative y, so we flip it to mean "forward".
	var input = get_input_vector()
	var move_dir = cam_right * input.x + cam_forward * -input.y
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()    # stops diagonals being faster

	# 3. Ease toward the wanted speed (or toward 0 when nothing is pushed).
	velocity.x = lerp(velocity.x, move_dir.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, move_dir.z * speed, accel * delta)

	# 4. Gravity: pull down every frame.
	velocity.y -= gravity * delta

	# 5. Move. Godot handles sliding along walls.
	move_and_slide()

	# 6. On the ground, don't pile up downward speed.
	if is_on_floor():
		velocity.y = -0.1

	# 7. Roll the visible ball to match the movement.
	_roll_mesh(delta)


func _roll_mesh(delta):
	var flat = Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.1:
		# A ball rolls around the axis sideways to its movement.
		var axis = Vector3.UP.cross(flat).normalized()
		var angle = flat.length() * delta / ball_radius
		mesh.global_rotate(axis, angle)
		mesh.transform = mesh.transform.orthonormalized()   # clean up rounding errors


func die():
	# Called by an enemy that caught us.
	if dead:
		return
	dead = true
	died.emit()
