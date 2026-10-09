extends Control
# Lives on "TouchControls". It does everything the touch UI needs:
#   1. Draws a joystick (ring + dot) in the bottom-left corner.
#      The joystick ONLY moves the ball. It never touches the camera.
#   2. Turns the camera when you drag anywhere ELSE on the screen.
# It works with fingers AND the mouse (left button).

# --- Settings you can tweak in the Inspector ---

# Joystick ring size, as a fraction of the screen HEIGHT.
# 0.11 = the ring's radius is 11% of the screen height.
# Make this smaller for a smaller joystick, bigger for a bigger one.
@export var joy_size = 0.11

# Gap between the joystick and the screen edges, as a fraction of screen height.
@export var margin_size = 0.07

# Ignore tiny pushes near the centre, so the ball doesn't drift (0 to 1).
@export var dead_zone = 0.15

# How much bigger than the ring the touch area is. 1.3 means a touch just
# outside the ring still grabs the joystick, which is easier on a thumb.
@export var grab_scale = 1.3

# --- Constants ---

# The mouse has no finger number, so we give it a fake one.
# Real fingers are numbered 0, 1, 2..., so 100 never clashes with them.
const MOUSE_ID = 100

# --- Variables ---

# The result the Player reads: x = left/right, y = up/down, each -1 to 1.
# Pushing up gives a negative y.
var move_vector = Vector2.ZERO

# Which finger (or the mouse) is holding the joystick. -1 means nobody.
var joy_id = -1

# Which finger (or the mouse) is dragging the camera. -1 means nobody.
var look_id = -1

# How far the dot is from the ring's centre right now (for drawing).
var knob_offset = Vector2.ZERO

# The CameraPivot we turn. Game.gd gives us this when the game starts.
var camera_pivot = null


func _ready():
	# Stretch over the whole screen, so we can draw anywhere and see all touches.
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Let touches pass through this node to the buttons on the end screen.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Stop working while the game is paused (for example on the end screen).
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# If the window changes size, redraw so the joystick stays in the corner.
	get_viewport().size_changed.connect(queue_redraw)
	add_to_group("touch_controls")

func _find_pivot():
	# Finds the camera pivot by looking inside the Player.
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_node("CameraPivot"):
		camera_pivot = players[0].get_node("CameraPivot")


func setup(pivot):
	# Called once by Game.gd, so we know which camera to turn.
	camera_pivot = pivot


func get_move_vector():
	# The Player asks for this to know where to move.
	return move_vector


# ---------- Measuring ----------

func _joy_radius():
	# Ring radius in pixels, based on the screen height.
	return get_viewport_rect().size.y * joy_size


func _knob_radius():
	# The dot is 40% the size of the ring.
	return _joy_radius() * 0.4


func _joy_center():
	# Centre of the joystick ring: bottom-left corner of the screen.
	var s = get_viewport_rect().size
	var m = s.y * margin_size
	var r = _joy_radius()
	return Vector2(m + r, s.y - m - r)


# ---------- Drawing ----------

func _draw():
	# Draws the joystick. Runs at the start and whenever we call update().
	var dark = Color("242D2E")
	var gold = Color("F9B623")
	var off = Color("F5F5F5")

	var c = _joy_center()
	var r = _joy_radius()

	# The ring: a soft dark disc with an off-white outline.
	draw_circle(c, r, Color(dark.r, dark.g, dark.b, 0.45))
	draw_arc(c, r, 0, TAU, 48, Color(off.r, off.g, off.b, 0.7), 3.0, true)

	# The dot, following the finger. It lights up gold while held.
	var dot_color = gold if joy_id != -1 else off
	draw_circle(c + knob_offset, _knob_radius(), Color(dot_color.r, dot_color.g, dot_color.b, 0.9))


# ---------- Input handling ----------

func _input(event):
	# Runs for every input event. Fingers and the mouse use the same helpers.
	
	# On a phone, Godot also sends a fake mouse event for every touch, so that
	# buttons work. We already handle the real touch events, so ignore the fake
	# mouse ones. On PC the mouse is still used normally.
	if OS.get_name() == "Android" and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return


	# A finger touched or lifted.
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)

	# A finger moved.
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)

	# The left mouse button was pressed or released.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(MOUSE_ID, event.position)
		else:
			_release(MOUSE_ID)

	# The mouse moved.
	elif event is InputEventMouseMotion:
		_drag(MOUSE_ID, event.position, event.relative)


func _press(id, pos):
	# Something just pressed down. Decide what it's for.

	if joy_id == -1 and pos.distance_to(_joy_center()) <= _joy_radius() * grab_scale:
		# On the joystick (and it's free): this one controls MOVEMENT only.
		joy_id = id
		_move_knob(pos)
		# Tell the rest of the game "I've used this input", so nothing else
		# (like the camera) reacts to it as well.
		get_viewport().set_input_as_handled()

	elif look_id == -1:
		# Anywhere else (and the camera is free): this one controls the camera.
		look_id = id


func _release(id):
	# Something lifted. Stop whatever it was doing.
	if id == joy_id:
		joy_id = -1
		knob_offset = Vector2.ZERO    # dot snaps back to the centre
		move_vector = Vector2.ZERO    # ball stops being pushed
		queue_redraw()                # redraw
		get_viewport().set_input_as_handled()
	elif id == look_id:
		look_id = -1


func _drag(id, pos, rel):
	# Something moved. React only if it's the one holding that control.
	if id == joy_id:
		# Joystick finger: move the dot and the ball. Never the camera.
		_move_knob(pos)
		get_viewport().set_input_as_handled()
	elif id == look_id:
		# Camera finger: find the pivot if we don't have it yet, then turn it.
		if camera_pivot == null:
			_find_pivot()
		if camera_pivot != null:
			camera_pivot.rotate_view(rel)


func _move_knob(pos):
	# Moves the dot toward the finger and works out move_vector.
	var r = _joy_radius()

	# How far the finger is from the centre, capped so the dot stays in the ring.
	var offset = (pos - _joy_center()).limit_length(r)
	knob_offset = offset

	# Convert to -1..1. Pushing all the way to the edge = 1.
	var strength = offset / r

	# Ignore tiny pushes inside the dead zone.
	if strength.length() < dead_zone:
		move_vector = Vector2.ZERO
	else:
		move_vector = strength

	queue_redraw()   # redraw the dot in its new place
