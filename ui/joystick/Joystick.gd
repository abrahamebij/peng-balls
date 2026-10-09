extends Control
# This script lives on the "Joystick" node. Its only job is to work out
# which direction the player is pushing the joystick, and to move the
# Point (the dot) so it follows the player's finger OR the mouse.

# --- Settings you can tweak in the Inspector ---

# Ignore tiny pushes near the center, so the ball doesn't drift
# when your thumb rests on the stick (0 = off, 1 = max).
@export var dead_zone = 0.15

# How much bigger than the ring the touch area is. 1.3 means a touch just
# outside the ring still counts, which makes it easier to grab.
@export var grab_scale = 1.3

# Leave at 0 to use the Border's own size automatically.
# Set a number (in pixels) only if the radius comes out wrong.
@export var radius_override = 0.0

# --- Constants ---

# The mouse has no finger number, so we give it a fake one.
# Real fingers are numbered 0, 1, 2..., so 100 never clashes with them.
const MOUSE_ID = 100

# --- Variables the rest of the game reads ---

# The result: x = left/right, y = up/down, each from -1 to 1.
# Pushing up gives a negative y. The Player script turns this into movement.
var output = Vector2.ZERO

# Which finger (or the mouse) is holding the joystick.
# -1 means "nothing is holding it".
var touch_id = -1

# --- Shortcuts to the child nodes ---
@onready var border = $Border
@onready var point = $Point


func _ready():
	# Wait a moment so the layout is finished, then center the dot in the ring.
	call_deferred("_reset_point")
	# If the window size changes, center the dot again.
	get_viewport().connect("size_changed", Callable(self, "_reset_point"))


# ---------- Measuring helpers ----------

func _get_center():
	# Center of the ring in screen coordinates.
	return border.global_position + (border.size * border.scale) / 2.0


func _get_radius():
	# Radius of the ring. Use the override if one was set.
	if radius_override > 0.0:
		return radius_override
	return (border.size.x * border.scale.x) / 2.0


func _get_travel():
	# How far the dot may move from the center, so it stays inside the ring.
	var point_half = (point.size.x * point.scale.x) / 2.0
	return max(_get_radius() - point_half, 1.0)


func contains(pos):
	# Returns true if a screen position is on the joystick.
	# TouchControls.gd uses this to avoid treating joystick presses as camera drags.
	return pos.distance_to(_get_center()) <= _get_radius() * grab_scale


# ---------- Input handling ----------

func _input(event):
	# This runs for every input event. We sort it by type and pass it to
	# the helper functions below. A finger and the mouse end up in the
	# same helpers, which is why both work the same way.

	# A finger touched or lifted.
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release_if(event.index)

	# A finger moved.
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)

	# The left mouse button was pressed or released.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(MOUSE_ID, event.position)
		else:
			_release_if(MOUSE_ID)

	# The mouse moved.
	elif event is InputEventMouseMotion:
		_drag(MOUSE_ID, event.position)


func _press(id, pos):
	# Something (a finger or the mouse) pressed down.
	# Take it only if the joystick is free and the press landed on it.
	if touch_id == -1 and contains(pos):
		touch_id = id          # remember who is holding it
		_move_knob(pos)


func _release_if(id):
	# Something lifted. Only react if it was the one holding the joystick.
	if id == touch_id:
		_release()


func _drag(id, pos):
	# Something moved. Only react if it's the one holding the joystick.
	if id == touch_id:
		_move_knob(pos)


func _move_knob(pos):
	# Moves the dot toward the pointer and calculates "output".
	var travel = _get_travel()

	# How far the pointer is from the center, capped so the dot stays in the ring.
	var offset = (pos - _get_center()).limit_length(travel)
	_place_point(offset)

	# Convert to a -1..1 value. A full push to the edge = 1.
	var strength = offset / travel

	# Ignore tiny pushes inside the dead zone.
	if strength.length() < dead_zone:
		output = Vector2.ZERO
	else:
		output = strength


func _release():
	# Let go: free the joystick, stop moving, recenter the dot.
	touch_id = -1
	output = Vector2.ZERO
	_reset_point()


func _reset_point():
	# Put the dot back in the middle of the ring.
	_place_point(Vector2.ZERO)


func _place_point(offset):
	# Positions the dot at (ring center + offset).
	# We subtract half the dot's size because a node's position is its
	# top-left corner, but we want its middle to land on the target.
	var half = (point.size * point.scale) / 2.0
	point.global_position = _get_center() + offset - half
