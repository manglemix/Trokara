# A base class for developing 3D terrestrial entities which are controllable by both AI and users through a common interface
class_name Character
extends KinematicBody


enum SerialEnums {POSITION, NORMAL, TRAVEL, REMAINDER, COLLIDER, COLLIDER_SHAPE, COLLIDER_VELOCITY, COLLISION_TIME}

# emitted when this node contacts a floor or a slope; vertical_speed is the speed along the up_vector at the moment of collision
signal landed(vertical_speed)

# emitted when this node hits a wall
signal touched_wall(normal_velocity)

# multiplied with the project's gravity, useful for parachutes
export var gravity_factor := 1.0 setget set_gravity_factor

# if true, this node will try to stick to the ground, if the ground is within the snap distance
export var snap_to_floor := true

# used in move_and_slide_with_snap to stick to the floor (the export hint can be changed if needed)
export(float, 0, 10) var snap_distance := 0.05

# the maximum angle of a slope which can be climbed (used in move_and_slide_with_snap)
export(float, 0, 180) var floor_max_angle_degrees := 45.0 setget set_floor_max_angle_degrees

# if true, the character will not move up walls (but can still slide down them)
export var dont_slide_up_walls := true

# if true, the character will keep track of adjacent walls even if the character is not moving (or is moving parallel to the wall)
export var track_wall := false

# the radian counterpart
var floor_max_angle := PI / 4 setget set_floor_max_angle

# The speed and direction this character is moving towards. Do not set this directly if snapped to floor, use apply_impulse
var linear_velocity: Vector3

# the speed and direction this character will move towards (in global space)
var movement_vector: Vector3

# the direction this node considers as down, originally uses the default gravity vector in project settings
var down_vector: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector") setget set_down_vector

# the opposite of the down_vector
var up_vector: Vector3 = - down_vector setget set_up_vector

# the speed at which this node descends
var gravity_acceleration: float = ProjectSettings.get_setting("physics/3d/default_gravity") setget set_gravity_acceleration

# contains information about the collision with a floor in each frame
# floors are slopes whose incline is less than floor_max_angle
var floor_collision: Array

# contains information about the last valid collision with the floor
# is never null, unless the character has never touched a floor
var last_floor_collision: Array

# contains information about the collision with a slope in each frame
var wall_collision: Array

# contains information about the last valid collision with a slope
# is never null, unless the character has never touched a slope
var last_wall_collision: Array

# if true, floor checks will be paused
var lock_floor := false

# if true, the snapping feature is temporarily disabled until this node is falling
# this is so that this node does not snap to the floor when jumping upwards
var _impulsing := false


func set_floor_max_angle_degrees(value: float) -> void:
	floor_max_angle_degrees = value
	floor_max_angle = deg2rad(value)


func set_floor_max_angle(value: float) -> void:
	floor_max_angle = value
	floor_max_angle_degrees = rad2deg(value)


func set_gravity_factor(value: float) -> void:
	gravity_acceleration *= value / gravity_factor
	gravity_factor = value


func set_down_vector(vector: Vector3) -> void:
	assert(vector.is_normalized())
	down_vector = vector
	up_vector = - vector


func set_up_vector(vector: Vector3) -> void:
	assert(vector.is_normalized())
	up_vector = vector
	down_vector = - vector


func set_gravity_acceleration(value: float) -> void:
	gravity_factor = value / (gravity_acceleration / gravity_factor)
	gravity_acceleration = value


func read_project_settings() -> void:
	# Since there's no way to know if the ProjectSettings were updated, this method must be called when there is a change
	gravity_acceleration = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_factor
	set_down_vector(ProjectSettings.get_setting("physics/3d/default_gravity_vector"))


func get_vertical_speed() -> float:
	return linear_velocity.dot(up_vector)


func align_to_floor(vector: Vector3) -> Vector3:
	# this will rotate the vector given on the plane formed by the vector and the up vector, such that the vector is along the floor plane
	# returns the vector perpendicular to the up_vector if there is no floor
	if is_on_floor():
		return up_vector.cross(vector).cross(floor_collision[SerialEnums.NORMAL]).normalized() * vector.length()
	
	else:
		var cross_product := up_vector.cross(vector).normalized()
		
		if cross_product.is_normalized():
			return up_vector.rotated(cross_product, PI / 2) * vector.length()
		
		# if the cross product is not normalized, it means that vector is along the up vector, and therefore cannot be aligned
		return vector


func temporary_unsnap() -> void:
	# Call this method before changing linear_velocity if the character is on the floor
	# this ensures that you can jump without remaining snapped
	if snap_to_floor:
		_impulsing = true
		snap_to_floor = false
		floor_collision = []


func _integrate_movement(vector: Vector3, _delta: float) -> Vector3:
	# transforms the vector given according to some algorithm
	# this is mainly used to determine how the movement_vector affects the linear_velocity
	# right now this will only allow the character to move when it is on the ground
	# linear_velocity should not be set in this function
	if is_on_floor():
		return align_to_floor(vector)
		
	else:
		return linear_velocity


func is_floor(collision: Array) -> bool:
	# checks if the collision data (from serial_move_and_collide) is a floor
	return collision[SerialEnums.NORMAL].angle_to(up_vector) <= floor_max_angle


func is_on_floor() -> bool:
	return not floor_collision.empty()


func is_on_wall() -> bool:
	return not wall_collision.empty()


func _physics_process(delta: float):
	# warning-ignore-all:return_value_discarded
	linear_velocity = _integrate_movement(movement_vector, delta)
	
	var was_on_floor := is_on_floor()
	var was_on_wall := is_on_wall()
	floor_collision = []
	wall_collision = []
	
	if not was_on_floor and _impulsing:
		_impulsing = false
		snap_to_floor = true
	
	# test vector is the direction we check if a floor is present
	# the moment the character is initialised, we check the down vector
	# but after the first contact, we check in the direction of the last floor normal
	var test_vector := down_vector if last_floor_collision.empty() else - last_floor_collision[SerialEnums.NORMAL]
	var travel_vector := linear_velocity * delta
	
	# main movement code
	# I stayed away from move_and_slide_and_snap as it caused this node to slide down slopes even if stop on slope was true (and there was downward velocity)
	# and for some reason had a bug when nearing the max floor angle, which caused this node to randomly shoot upwards at high speeds
	# also, if there was any side to side movement on a slope, move_and_slide_and_snap would cause this node to drift downards
	# move_and_slide had too little freedom
	if not is_zero_approx(travel_vector.length()):
		var collision := serial_move_and_collide(travel_vector)
		
		if not collision.empty():
			if is_floor(collision):
				# it is possible to somehow hit a floor when moving up to it (hard to explain)
				# So this code filters that out
				var dot_product := linear_velocity.dot(test_vector)
				if is_zero_approx(dot_product) or dot_product > 0:
					floor_collision = collision
			
			elif was_on_floor and dont_slide_up_walls:
				# when hitting a wall, the character will slide up the wall, but that is not desired
				# so the movement will be corrected to slide along the wall (not up the wall)
				move_and_collide(((travel_vector - travel_vector.project(up_vector)).normalized() * travel_vector.length()).slide((collision[SerialEnums.NORMAL] - collision[SerialEnums.NORMAL].project(up_vector)).normalized()) - collision[SerialEnums.TRAVEL])
			
			else:
				move_and_collide(collision[SerialEnums.REMAINDER].slide(collision[SerialEnums.NORMAL]))
	
	# wall tracking
	# so that even if the character isn't moving but is touching a wall, wall_collision will still update
	if track_wall and not is_on_wall() and was_on_wall and not last_wall_collision.empty():
		var collision := serial_move_and_collide(- last_wall_collision[SerialEnums.NORMAL] * get("collision/safe_margin"), true, true, true)
		
		if not collision.empty():
			_sort_collision(collision)
	
	# floor tracking
	if not is_on_floor() and (was_on_floor or get_vertical_speed() <= 0):
		# this will check if the character is standing directly on a floor
		var collision := serial_move_and_collide(test_vector * get("collision/safe_margin"), true, true, true)
		
		if not collision.empty():
			_sort_collision(collision)
		
		elif was_on_floor and snap_to_floor:
			# if the character is not on a floor, but it was in the last frame,
			# the character will try to snap to a surface (which can be a floor or a steep wall)
			# which is when it checks further for a surface
			collision = serial_move_and_collide(test_vector * snap_distance, true, true, true)
			
			if not collision.empty():
				_sort_collision(collision)
				# if there was a surface, the character will move down to it, while still not moving faster than normal
				global_transform.origin += (travel_vector + collision[SerialEnums.TRAVEL]).normalized() * travel_vector.length() - travel_vector
				# then the velocity will be aligned to the new floor (or not if it was a wall)
				linear_velocity = align_to_floor(linear_velocity)
	
	if is_on_floor():
		last_floor_collision = floor_collision
		
		if not was_on_floor:
			var vertical_speed := get_vertical_speed()
			emit_signal("landed", vertical_speed)
			linear_velocity += vertical_speed * down_vector
	
	else:
		linear_velocity += down_vector * gravity_acceleration * delta
	
	if is_on_wall():
		last_wall_collision = wall_collision
		
		if not was_on_wall:
			emit_signal("touched_wall", travel_vector.project(wall_collision[SerialEnums.NORMAL]) / delta)


func serial_move_and_collide(rel_vec: Vector3, infinite_inertia: bool = true, exclude_raycast_shapes: bool = true, test_only: bool = false) -> Array:
	# Extends move_and_collide to return an array instead of KinematicCollision
	# This is because of this weird property where only 1 KinematicCollision instance exists within a frame within a single KinematicBody
	# Meaning wall_collision and floor_collision could be the same instance even if they were created in different move_and_collide methods
	# If you don't understand that, it's fine, because this is a private method so you shouldn't call it
	var collision := move_and_collide(rel_vec, infinite_inertia, exclude_raycast_shapes, test_only)
	
	if collision:
		return [collision.position, collision.normal, collision.travel, collision.remainder, collision.collider, collision.collider_shape, collision.collider_velocity, OS.get_system_time_msecs()]
	
	return []


func _sort_collision(collision: Array) -> void:
	if is_floor(collision):
		if not lock_floor:
			floor_collision = collision
	
	else:
		wall_collision = collision
