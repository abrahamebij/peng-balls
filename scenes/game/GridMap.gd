extends GridMap
# Lives on the GridMap. At game start it measures the "Ground", builds a
# random maze that covers the whole Ground, and places the wall blocks.
# Walls are always 1 block thick. Corridors are "corridor_width" blocks wide.

# --- Settings you can tweak in the Inspector ---

# Path to the Ground node. "../Ground" means "a sibling of the GridMap".
@export var ground_path: NodePath = NodePath("../Ground")

# Which item in your MeshLibrary is the wall block (starts at 0).
@export var wall_item = 0

# How many blocks tall the walls are.
@export var wall_height = 3

# How many blocks wide each corridor is. Bigger = a looser, simpler maze.
@export var corridor_width = 13

# How many of the remaining walls between rooms get knocked down, from
# 0 (a pure maze, lots of dead ends) to 1 (almost no walls between rooms).
# 0.4 is a good loose maze with plenty of loops.
@export var openness = 0.2 # (float, 0.0, 1.0)

# --- Variables ---

# The maze as a grid of true/false values (one entry per block).
# true = wall block, false = open floor.
var walls = []

# Size of the maze in blocks.
var grid_w = 0
var grid_h = 0

# Size of the maze in rooms (how many across and down).
var rooms_x = 0
var rooms_y = 0

# World position of the middle of every room.
var room_centers = []

# World position of every open floor block. Used to place coins and enemies.
var floor_cells = []


func _ready():
	randomize()   # a different maze each run
	generate()


func generate():
	# Builds the whole maze.
	clear()   # remove any blocks drawn by hand in the editor

	# Make sure blocks sit exactly inside their cells.
	cell_center_x = true
	cell_center_y = true
	cell_center_z = true

	# Step 1: measure the Ground.
	var ground = get_node(ground_path)
	var ground_mesh = _find_mesh(ground)
	if ground_mesh == null:
		push_error("Maze: no MeshInstance3D found inside the Ground node.")
		return
	var box = ground_mesh.global_transform * ground_mesh.get_aabb()

	# Step 2: work out how many blocks fit on the Ground.
	var cols = int(floor(box.size.x / cell_size.x))
	var rows = int(floor(box.size.z / cell_size.z))

	# Step 3: work out how many rooms fit.
	# Each room takes (corridor_width + 1) blocks (the room plus one wall),
	# and the maze needs one extra wall block at the end.
	var step = corridor_width + 1
	rooms_x = max(int(floor((cols - 1) / float(step))), 2)
	rooms_y = max(int(floor((rows - 1) / float(step))), 2)
	grid_w = rooms_x * step + 1
	grid_h = rooms_y * step + 1

	# Step 4: line the GridMap up with the Ground.
	# Any leftover space is split evenly on both sides.
	var leftover_x = box.size.x - grid_w * cell_size.x
	var leftover_z = box.size.z - grid_h * cell_size.z
	var origin = Vector3(
		box.position.x + leftover_x / 2.0,
		box.position.y + box.size.y,        # walls start on top of the Ground
		box.position.z + leftover_z / 2.0)
	global_transform = Transform3D(Basis(), origin)   # no rotation, no scale

	# Step 5: start with everything as wall.
	walls = []
	for x in range(grid_w):
		var column = []
		for z in range(grid_h):
			column.append(true)
		walls.append(column)

	# Step 6: carve out the rooms and the passages between them.
	_carve()
	_add_openings()

	# Step 7: place the wall blocks, and remember every open floor spot.
	floor_cells = []
	for x in range(grid_w):
		for z in range(grid_h):
			if walls[x][z]:
				for y in range(wall_height):
					set_cell_item(Vector3i(x, y, z), wall_item)
			else:
				floor_cells.append(_cell_to_world(x, z))

	# Step 8: remember the middle of each room.
	room_centers = []
	for i in range(rooms_x):
		for j in range(rooms_y):
			room_centers.append(_room_to_world(i, j))


func _find_mesh(node):
	# Finds the MeshInstance in the Ground (or the Ground itself if it is one).
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
	return null


# ---------- Small helpers ----------

func _room_start(i, j):
	# The first block (top-left corner) of room (i, j). +1 skips the border wall.
	var step = corridor_width + 1
	return Vector2(1 + i * step, 1 + j * step)


func _open_room(i, j):
	# Removes all the wall blocks inside room (i, j), making it open floor.
	var s = _room_start(i, j)
	for dx in range(corridor_width):
		for dz in range(corridor_width):
			walls[int(s.x) + dx][int(s.y) + dz] = false


func _passage_blocked(a, b):
	# True if the wall between two neighbouring rooms is still there.
	var lo = Vector2(min(a.x, b.x), min(a.y, b.y))
	var s = _room_start(lo.x, lo.y)
	if a.x != b.x:
		# Side by side: check the wall just right of the left room.
		return walls[int(s.x) + corridor_width][int(s.y)]
	else:
		# One above the other: check the wall just below the upper room.
		return walls[int(s.x)][int(s.y) + corridor_width]


func _open_passage(a, b):
	# Knocks down the wall between two neighbouring rooms, as wide as a corridor.
	var lo = Vector2(min(a.x, b.x), min(a.y, b.y))
	var s = _room_start(lo.x, lo.y)
	if a.x != b.x:
		for dz in range(corridor_width):
			walls[int(s.x) + corridor_width][int(s.y) + dz] = false
	else:
		for dx in range(corridor_width):
			walls[int(s.x) + dx][int(s.y) + corridor_width] = false


# ---------- Maze building ----------

func _carve():
	# "Random walk with backtracking": walk to a random room we haven't
	# visited yet, knocking down the wall between. When stuck, step back.
	# This guarantees every room can be reached.
	var dirs = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]

	# Keep track of which rooms we have already been to.
	var visited = []
	for i in range(rooms_x):
		var column = []
		for j in range(rooms_y):
			column.append(false)
		visited.append(column)

	visited[0][0] = true
	_open_room(0, 0)
	var stack = [Vector2(0, 0)]   # the path we're currently on

	while stack.size() > 0:
		var current = stack.back()

		# Collect neighbouring rooms that haven't been visited yet.
		var options = []
		for d in dirs:
			var n = current + d
			if n.x >= 0 and n.x < rooms_x and n.y >= 0 and n.y < rooms_y:
				if not visited[int(n.x)][int(n.y)]:
					options.append(n)

		if options.size() > 0:
			var next = options[randi() % options.size()]
			visited[int(next.x)][int(next.y)] = true
			_open_room(int(next.x), int(next.y))
			_open_passage(current, next)
			stack.append(next)
		else:
			stack.pop_back()   # dead end: go back one step


func _add_openings():
	# Makes the maze looser. We list every pair of neighbouring rooms, shuffle
	# the list, and open each still-blocked pair with a chance of "openness".
	var pairs = []
	for i in range(rooms_x):
		for j in range(rooms_y):
			var a = Vector2(i, j)
			if i + 1 < rooms_x:
				pairs.append([a, Vector2(i + 1, j)])
			if j + 1 < rooms_y:
				pairs.append([a, Vector2(i, j + 1)])
	pairs.shuffle()

	for p in pairs:
		if _passage_blocked(p[0], p[1]) and randf() < openness:
			_open_passage(p[0], p[1])


# ---------- Helpers for placing things in the maze ----------

func _cell_to_world(x, z):
	# World position of the middle of block (x, z), at floor level.
	var local = Vector3((x + 0.5) * cell_size.x, 0, (z + 0.5) * cell_size.z)
	return to_global(local)


func _room_to_world(i, j):
	# World position of the middle of room (i, j), at floor level.
	var s = _room_start(i, j)
	var local = Vector3(
		(s.x + corridor_width / 2.0) * cell_size.x,
		0,
		(s.y + corridor_width / 2.0) * cell_size.z)
	return to_global(local)


func get_start_position():
	# Where the player starts: the middle of the top-left room, lifted a little.
	var pos = _room_to_world(0, 0)
	pos.y += 1.0
	return pos


func pick_floor_positions(count, avoid_pos, min_from_avoid, min_between):
	# Returns up to "count" random floor positions that are:
	#   - at least min_from_avoid away from avoid_pos (e.g. the player's start)
	#   - at least min_between away from each other (so they spread out)
	# If the maze is too small to fit them all, it returns fewer.
	var cells = floor_cells.duplicate()
	cells.shuffle()
	var chosen = []
	for pos in cells:
		if chosen.size() >= count:
			break
		if pos.distance_to(avoid_pos) < min_from_avoid:
			continue
		var ok = true
		for c in chosen:
			if pos.distance_to(c) < min_between:
				ok = false
				break
		if ok:
			chosen.append(pos)
	return chosen
