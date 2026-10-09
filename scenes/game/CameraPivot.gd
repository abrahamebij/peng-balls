extends Node3D
# Lives on "CameraPivot", which sits at the centre of the ball.
# It does NOT read input itself. TouchControls calls rotate_view()
# when you drag on the screen (anywhere except the joystick).

# --- Settings you can tweak in the Inspector ---

# How fast the camera turns. Smaller = slower and smoother.
@export var sensitivity = 0.005

# Lowest and highest tilt, in radians. Negative = camera above looking down.
@export var min_pitch = -1.3
@export var max_pitch = -0.1

# --- Variables ---

# Current up/down tilt of the camera.
var pitch = -0.6

# --- Shortcuts to the child nodes ---
@onready var pitch_node = $Pitch
@onready var spring_arm = $Pitch/SpringArm3D


func _ready():
	# Start with a downward tilt so the maze is visible from above.
	pitch_node.rotation.x = pitch

	# The camera arm shouldn't be blocked by the player's own body,
	# only by the maze walls. (get_parent() is the Player.)
	spring_arm.add_excluded_object(get_parent().get_rid())


func rotate_view(relative):
	# Turns the camera by an amount of screen movement (in pixels).

	# Left/right movement turns the whole pivot (yaw).
	rotate_y(-relative.x * sensitivity)

	# Up/down movement tilts just the Pitch node, within the limits.
	pitch = clamp(pitch - relative.y * sensitivity, min_pitch, max_pitch)
	pitch_node.rotation.x = pitch
