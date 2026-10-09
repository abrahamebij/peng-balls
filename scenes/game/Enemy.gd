extends CharacterBody3D
# An enemy ball. Wanders around the maze, chases the player when it sees them,
# and ends the game if it touches the player.

# --- Settings you can tweak in the Inspector ---
@export var speed = 5.0             # slower than the player, so you can escape
@export var gravity = 30.0
@export var sight_range = 14.0      # how far it can see the player
@export var catch_distance = 1.6    # closer than this = player is caught

# --- Variables ---
var wander_dir = Vector3.ZERO      # the direction it's wandering in
var wander_timer = 0.0             # time left before picking a new direction
var player = null


func _ready():
	add_to_group("enemy")
	_pick_new_direction()


func _find_player():
	# Looks for the player in the "player" group.
	var found = get_tree().get_nodes_in_group("player")
	if found.size() > 0:
		player = found[0]


func _physics_process(delta):
	# If we haven't found the player yet, keep looking.
	if not is_instance_valid(player):
		_find_player()

	var move_dir = Vector3.ZERO
	var chasing = false

	if is_instance_valid(player):
		# Flat (ignoring height) vector from us to the player.
		var to_player = player.global_position - global_position
		to_player.y = 0
		var dist = to_player.length()

		# Close enough: the player is caught.
		if dist <= catch_distance:
			_catch(player)

		# Close and in view: chase.
		if dist <= sight_range and _can_see_player():
			move_dir = to_player.normalized()
			chasing = true

	if not chasing:
		# Wander. Pick a new direction when the timer runs out or we hit a wall.
		wander_timer -= delta
		if wander_timer <= 0.0 or is_on_wall():
			_pick_new_direction()
		move_dir = wander_dir

	# Move sideways, and apply gravity.
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	velocity.y -= gravity * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = -0.1

	# Also check what we physically bumped into this frame.
	# If it was the player, that's a catch too.
	for i in range(get_slide_collision_count()):
		var hit = get_slide_collision(i)
		var collider = hit.get_collider()
		if collider != null and collider.is_in_group("player"):
			_catch(collider)


func _catch(target):
	# Tells the player it has been caught.
	if target.has_method("die"):
		target.die()
	else:
		# This message means Player.gd is missing the die() function.
		print("Enemy touched the player, but the player has no die() function. Is Player.gd the newest version?")


func _pick_new_direction():
	# Choose one of the four straight directions (the maze runs on a grid).
	var dirs = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	wander_dir = dirs[randi() % dirs.size()]
	wander_timer = randf_range(1.5, 3.0)


func _can_see_player():
	# Fires an invisible line from us to the player.
	# If the first thing it hits is the player, nothing is in the way.
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, player.global_position)
	query.exclude = [get_rid()]
	var hit = space.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player
