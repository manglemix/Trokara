# A base class for developing terrestrial entities which are controllable by both AI and users through a common interface
class_name Character2D
extends KinematicBody2D


# emitted when this node contacts a floor or a slope; vertical_speed is the speed along the up_vector at the moment of collision
signal landed(vertical_speed, on_floor)

# multiplied with the project's gravity, useful for parachutes
export var gravity_factor := 1.0 setget set_gravity_factor

# used in move_and_slide_with_snap to stick to the floor
export var snap_distance := 0.05

# the maximum angle of a slope which can be climbed (used in move_and_slide_with_snap)
export var floor_max_angle_degrees := 45.0 setget set_floor_max_angle_degrees

# the radian counterpart
var floor_max_angle := PI / 4 setget set_floor_max_angle

# The speed and direction this character is moving towards. Do not set this directly if snapped to floor, use apply_impulse
var linear_velocity: Vector2

# the speed and direction this character will move towards (in global space)
var movement_vector: Vector2

# the direction this node considers as down, originally uses the default gravity vector in project settings
var down_vector: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector") setget set_down_vector

# the opposite of the down_vector
var up_vector: Vector2 = - down_vector setget set_up_vector

# the speed at which this node descends
var gravity_acceleration: float = ProjectSettings.get_setting("physics/2d/default_gravity") setget set_gravity_acceleration

# contains information about the collision with a floor in each frame
# floors are slopes whose incline is less than floor_max_angle
var floor_collision: KinematicCollision2D

# contains information about the last valid collision with the floor
# is never null, unless the character has never touched a floor
var last_floor_collision: KinematicCollision2D

# the system time of the last valid floor collision in milliseconds
var last_floor_time_msecs: int

# contains information about the collision with a slope in each frame
var slope_collision: KinematicCollision2D

# contains information about the last valid collision with a slope
# is never null, unless the character has never touched a slope
var last_slope_collision: KinematicCollision2D

# the system time of the last valid slope collision in milliseconds
var last_slope_time_msecs: int

# if true, this node will try to stick to the ground, if the ground is within the snap distance
var snap_to_floor := true

# if true, floor checks will be paused
var lock_floor := false

# if true, the snapping feature is temporarily disabled until this node is falling
# this is so that this node does not snap to the floor when jumping upwards
var _impulsing := false


func set_floor_max_angle_degrees(value: float) -> void:
	floor_max_angle_degrees = value


func set_floor_max_angle(value: float) -> void:
	floor_max_angle = value
	floor_max_angle_degrees = rad2deg(value)


func set_gravity_factor(value: float) -> void:
	gravity_acceleration *= value / gravity_factor
	gravity_factor = value


func set_down_vector(vector: Vector2) -> void:
	assert(vector.is_normalized())
	down_vector = vector
	up_vector = - vector


func set_up_vector(vector: Vector2) -> void:
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


func align_to_floor(vector: Vector2) -> Vector2:
	# this will rotate the vector given on the plane formed by the vector and the up vector, such that the vector is along the floor plane
	# returns the vector perpendicular to the up_vector if there is no floor
	if is_on_floor():
		return vector.slide(floor_collision.normal).normalized() * vector.length()
	
	else:
		return Vector2(- up_vector.y, up_vector.x) * sign(up_vector.cross(vector)) * vector.length()


func is_on_floor() -> bool:
	# overrides the function to check floor_collision instead
	# this is because this node doesn't use move_and_slide_with_snap
	return is_instance_valid(floor_collision)


func is_on_slope() -> bool:
	# returns true if the character is on a slope
	return is_instance_valid(slope_collision)


func apply_impulse(velocity: Vector2) -> void:
	# provides an easy way to add velocity to linear_velocity, whilst this node is currently snapped to the floor
	# not necessary if already in the air
	if snap_to_floor:
		_impulsing = true
		snap_to_floor = false
		floor_collision = null
	
	linear_velocity += velocity


func _integrate_movement(vector: Vector2, _delta: float) -> Vector2:
	# transforms the vector given according to some algorithm
	# this is mainly used to determine how the movement_vector affects the linear_velocity
	# right now this will only allow the character to move when it is on the ground
	# linear_velocity should not be set in this function
	if is_on_floor():
		return align_to_floor(vector)
		
	else:
		return linear_velocity


func _physics_process(delta):
	var vertical_speed := get_vertical_speed()
	
	if not _impulsing and not lock_floor:
		# checks if this node is directly on a slope
		# we can't just cast the shape as far as the snap distance, as it tends to overshoot if this node is directly on a slope
		# the overshooting will cause an overcompensation when snapping, causing sliding on slopes
		var was_on_slope := is_on_slope()
		slope_collision = move_and_collide(down_vector * get("collision/safe_margin"), true, true, true)
		
		if is_on_slope():
			# if on a slope, check if it is a floor
			if not _check_slope(vertical_speed, was_on_slope):
				floor_collision = null
			
		elif snap_to_floor and vertical_speed * delta > - snap_distance:
			# this section of code checks if there is a slope further down, then checks if it is a floor
			# if there is a floor, this character will move down towards it
			slope_collision = move_and_collide(down_vector * snap_distance, true, true, true)
			
			if is_on_slope() and _check_slope(vertical_speed, was_on_slope):
				global_transform.origin += floor_collision.travel
			
			else:
				floor_collision = null
		
		else:
			floor_collision = null
	
	linear_velocity = _integrate_movement(movement_vector, delta)
	
	if not is_on_floor():
		linear_velocity += down_vector * gravity_acceleration * delta
		
		if _impulsing and not is_instance_valid(move_and_collide(down_vector * snap_distance, true, true, true)):
			_impulsing = false
			snap_to_floor = true
	
	# I stayed away from move_and_slide_and_snap as it caused this node to slide down slopes even if stop on slope was true (and there was downward velocity)
	# and for some reason had a bug when nearing the max floor angle, which caused this node to randomly shoot upwards at high speeds
	# also, if there was any side to side movement on a slope, move_and_slide_and_snap would cause this node to drift downards
	linear_velocity = move_and_slide(linear_velocity, up_vector, true, 4, floor_max_angle)


func _check_slope(vertical_speed: float, was_on_slope: bool) -> bool:
	# private function, returns true if slope_collision is a floor
	# assumes slope_collision is not null
	last_slope_collision = slope_collision
	last_slope_time_msecs = OS.get_system_time_msecs()
	if abs(slope_collision.normal.angle_to(up_vector)) <= floor_max_angle:
		var was_on_floor = not is_on_floor()
		floor_collision = slope_collision
		last_floor_collision = slope_collision
		last_floor_time_msecs = last_slope_time_msecs
		
		if not was_on_floor:
			# needs to be emitted afterwards just in case apply_impulse is called because of this signal
			# if it was called before setting the variables above, the floor_collision would be valid even while _impulsing (which would be wrong)
			emit_signal("landed", vertical_speed, true)
		
		return true
	
	else:
		if not was_on_slope:
			emit_signal("landed", vertical_speed, false)
		
		return false
