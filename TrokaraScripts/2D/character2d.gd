# A base class for developing terrestrial entities which are controllable by both AI and users through a common interface
class_name Character2D
extends KinematicBody2D


signal landed(vertical_speed)		# emitted when this node contacts the floor; vertical_speed is the speed along the up_vector at the moment of collision

# multiplied with the project's gravity, useful for parachutes
export var gravity_factor := 1.0 setget set_gravity_factor

# used in move_and_slide_with_snap to stick to the floor
export var snap_distance := 0.05

# the maximum angle of a slope which can be climbed (used in move_and_slide_with_snap)
export var floor_max_angle_degrees := 45.0 setget set_floor_max_angle_degrees

# the radian counterpart
var floor_max_angle := PI / 4 setget set_floor_max_angle

var linear_velocity: Vector2

# the speed and direction this character will move towards (in global space)
var movement_vector: Vector2

# the direction this node considers as down, originally uses the default gravity vector in project settings
var down_vector: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector") setget set_down_vector

# the opposite of the down_vector
var up_vector: Vector2 = - down_vector setget set_up_vector

# the amount of time since the last contact with the floor
var air_time := 0.0

# the speed at which this node descends
var gravity_acceleration: float = ProjectSettings.get_setting("physics/2d/default_gravity") setget set_gravity_acceleration

# contains information about the last collision with the floor
var floor_collision: KinematicCollision2D

# if true, this node will try to stick to the ground, if the ground is within the snap distance
var snap_to_floor := true

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
	# returns vector if not on floor
	if is_on_floor():
		return vector.slide(floor_collision.normal).normalized() * vector.length()
	
	else:
		return vector


func test_floor(distance: float = get("collision/safe_margin"), max_angle := floor_max_angle) -> KinematicCollision2D:
	# Returns a KinematicCollision if there is a floor along the down_vector
	var result := move_and_collide(down_vector * distance, true, true, true)
	# check if the KinematicCollision exists (means there was a collision), and if the incline of the floor normal is less than the max_slope_angle
	if is_instance_valid(result) and result.normal.angle_to(up_vector) <= max_angle:
		return result
	
	return null


func is_on_floor() -> bool:
	# override the function to check floor_collision instead
	# this is because this node doesn't use move_and_slide_with_snap
	return is_instance_valid(floor_collision)


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
		return vector
		
	else:
		return linear_velocity


func _physics_process(delta: float):
	var vertical_speed := get_vertical_speed()
	
	if not _impulsing:
		# checks if this node is directly on the floor
		# we can't just cast the shape as far as the snap distance, as it tends to overshoot if this node is directly on the floor
		# the overshooting will cause an overcompensation when snapping, causing sliding on slopes
		floor_collision = test_floor()
		
		if snap_to_floor and (not is_on_floor()) and vertical_speed * delta > - snap_distance:
			# this section of code checks if the floor is within distance, and will try to move this node onto it
			floor_collision = test_floor(snap_distance)
			
			if is_on_floor():
				global_transform.origin += floor_collision.travel
		
		if is_on_floor() and air_time > 0:
			# This code is here and not in the other if statement below because the "landed" signal may call functions which can delete floor_collision (for impulsing)
			air_time = 0
			emit_signal("landed", vertical_speed)
			
			# remove any downward vertical speed so that we don't slam down onto slopes after snapping
			if vertical_speed < 0:
				linear_velocity -= vertical_speed * up_vector
	
	linear_velocity = _integrate_movement(movement_vector, delta)
	
	if is_on_floor():
		# this will prevent speed loss due to sliding, and will allow the character to run down slopes
		linear_velocity = align_to_floor(linear_velocity)
		
	else:
		air_time += delta
		linear_velocity += down_vector * gravity_acceleration * delta
		
		if _impulsing and get_vertical_speed() <= 0:
			_impulsing = false
			snap_to_floor = true
	
	# I stayed away from move_and_slide_and_snap as it caused this node to slide down slopes even if stop on slope was true (and there was downward velocity)
	# and for some reason had a bug when nearing the max floor angle, which caused this node to randomly shoot upwards at high speeds
	# also, if there was any side to side movement on a slope, move_and_slide_and_snap would cause this node to drift downards
	linear_velocity = move_and_slide(linear_velocity, up_vector, true, 4, floor_max_angle)
