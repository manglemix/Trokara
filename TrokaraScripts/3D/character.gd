# A base class for developing 3D terrestrial entities which are controllable by both AI and users through a common interface
class_name Character3D
extends KinematicBody


# emitted when this node contacts a floor or a slope; vertical_speed is the speed along the up_vector at the moment of collision
signal landed(vertical_speed)

# emitted when this node hits a wall
signal touched_wall(normal_velocity)

# emitted before either landed or touched wall
# Basically just a generic signal for any kind of collision
signal body_entered(body)

# multiplied with the project's gravity, useful for parachutes
export var gravity_factor := 1.0 setget set_gravity_factor

# used in move_and_slide_with_snap to stick to the floor (the export hint can be changed if needed)
export(float, 0, 10) var snap_distance := 0.05

# the maximum angle of a slope which can be climbed
export(float, 0, 180) var floor_max_angle_degrees := 45.0 setget set_floor_max_angle_degrees

# if true, the character will keep track of adjacent walls even if the character is not moving (or is moving parallel to the wall)
# there are few reasons to disable this, one of them is for performance
export var track_wall := true

# The max number of slides (changes to velocity) that can occur in a frame (used in the move_and_slide implementation)
export var max_slides := 8

# If true, will push RigidBodies aside as if they didn't exist
# Otherwise, proper RigidBody support will occur (where the Character can push them or weigh them down)
export var infinite_inertia := false

# The mass used when calculating Character & RigidBody interactions
# Only useful if infinite_inertia is false
export var mass := 5.0

# the radian counterpart
var floor_max_angle := PI / 4 setget set_floor_max_angle
 
# The speed and direction this character is moving towards. Do not set this directly if snapped to floor, use apply_impulse
# Keep in mind this is not always the true linear_velocity of the character
# It is not inclusive of friction, or the velocity of the platform the character may be on
var linear_velocity: Vector3

# the speed and direction this character will move towards (in global space)
# this is what the player and AI will control
var movement_vector: Vector3

# the direction this node considers as down, originally uses the default gravity vector in project settings
var down_vector: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector") setget set_down_vector

# the opposite of the down_vector
var up_vector: Vector3 = - down_vector setget set_up_vector

# the acceleration at which this node descends at
# IMPORTANT NOTE, this is the acceleration AFTER gravity_factor has been applied
var gravity_acceleration: float = ProjectSettings.get_setting("physics/3d/default_gravity") setget set_gravity_acceleration

var floor_velocity: Vector3

var last_floor_velocity: Vector3

# contains information about the collision with a floor in each frame
# floors are slopes whose incline is less than floor_max_angle
var floor_collision: CollisionData3D

# contains information about the last valid collision with the floor
# is never null, unless the character has never touched a floor
var last_floor_collision: CollisionData3D

# contains information about the collision with a slope in each frame
var wall_collision: CollisionData3D

# contains information about the last valid collision with a slope
# is never null, unless the character has never touched a slope
var last_wall_collision: CollisionData3D

# if true, the snapping feature is temporarily disabled until this node is falling
# this is so that this node does not snap to the floor when jumping upwards
var _impulsing := false

# The last floor collider node, used for following moving platforms
# The difference from last_floor_collision is that this is refreshed each frame
var _last_floor_collider: Spatial

# The last floor collider transform, used for following moving platforms
var _last_floor_collider_transform: Transform


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
	# Returns the signed vertical speed
	return linear_velocity.dot(up_vector)


func align_to_floor(vector: Vector3) -> Vector3:
	# this will rotate the vector given on the plane formed by the vector and the up vector, such that the vector is along the floor plane
	# returns the vector perpendicular to the up_vector if there is no floor
	if is_on_floor():
		return up_vector.cross(vector).cross(floor_collision.normal).normalized() * vector.length()
	
	else:
		var cross_product := up_vector.cross(vector).normalized()
		
		if cross_product.is_normalized():
			return up_vector.rotated(cross_product, PI / 2) * vector.length()
		
		# if the cross product is not normalized, it means that vector is along the up vector, and therefore cannot be aligned
		return vector


func temporary_unsnap() -> void:
	# Call this method before changing linear_velocity if the character is on the floor
	# this ensures that you can jump without remaining snapped
	_impulsing = true
	floor_collision = null


func _integrate_movement(vector: Vector3, _delta: float) -> Vector3:
	# transforms the vector given according to some algorithm
	# this is mainly used to determine how the movement_vector affects the linear_velocity
	# right now this will only allow the character to move when it is on the ground
	# linear_velocity should not be set in this function
	if is_on_floor():
		return vector
		
	else:
		return linear_velocity


func is_on_floor() -> bool:
	return floor_collision != null


func is_on_wall() -> bool:
	return wall_collision != null


func get_floor_velocity() -> Vector3:
	return floor_velocity


func get_slide_collision(_idx: int) -> KinematicCollision:
	# Since we don't use move_and_slide, there should be no use of this
	push_warning("Attempted to use unimplemented method get_slide_collision in Character")
	return null


func get_slide_count() -> int:
	# Since we don't use move_and_slide, there should be no use of this
	push_warning("Attempted to use unimplemented method get_slide_count in Character")
	return 0


func recheck_collisions() -> void:
	if floor_collision != null and not is_instance_valid(floor_collision.collider):
		floor_collision = null
		linear_velocity += floor_velocity
		floor_velocity = Vector3.ZERO
	
	if wall_collision != null and not is_instance_valid(wall_collision.collider):
		wall_collision = null
	
	if last_floor_collision != null and not is_instance_valid(last_floor_collision.collider):
		last_floor_collision = null
	
	if last_wall_collision != null and not is_instance_valid(last_wall_collision.collider):
		last_wall_collision = null


func _physics_process(delta: float):
	# warning-ignore-all:return_value_discarded
	linear_velocity = _integrate_movement(movement_vector, delta)
	
	var travel_vector := linear_velocity * delta
	
	var tmp_floor_collision := floor_collision
	var tmp_wall_collision := wall_collision
	
	var was_on_floor := is_on_floor()
	var was_on_wall := is_on_wall()
	var is_sliding_on_floor := was_on_floor
	var is_sliding_on_wall := was_on_wall
	
	if was_on_floor:
		# Here, special responses to floors are handled
		# Any object which has constant_angular_velocity or constant_linear_velocity (such as StaticBody), will alter this node
		var collider := floor_collision.collider
		
		if is_instance_valid(collider):
			if "constant_angular_velocity" in collider:
				rotation += collider.constant_angular_velocity * delta
			
			if "constant_linear_velocity" in collider:
				floor_velocity = collider.constant_linear_velocity
				travel_vector += floor_velocity * delta
			
			# This is where moving floors are handled
			if _last_floor_collider == null or collider != _last_floor_collider:
				_last_floor_collider = collider
				_last_floor_collider_transform = collider.global_transform

			else:
				# We compare the difference from the current position to where the current position should've been based on the last transform of the floor
				var moving_floor_velocity: Vector3 = collider.global_transform.xform(_last_floor_collider_transform.affine_inverse().xform(global_transform.origin)) - global_transform.origin
				travel_vector += moving_floor_velocity
				floor_velocity += moving_floor_velocity / delta
				last_floor_velocity = floor_velocity
				_last_floor_collider_transform = collider.global_transform
		
		else:
			is_sliding_on_floor = false
			floor_collision = null
			_last_floor_collider = null

	else:
		_last_floor_collider = null
		_impulsing = false
	
	if was_on_wall:
		# wall special responses
		var collider := wall_collision.collider
		
		if is_instance_valid(collider):
			if "constant_angular_velocity" in collider:
				rotation += collider.constant_angular_velocity * delta
			
			if "constant_linear_velocity" in collider:
				travel_vector += collider.constant_linear_velocity * delta
		
		else:
			is_sliding_on_wall = false
			wall_collision = null
	
	# main movement code
	# I stayed away from move_and_slide_and_snap as it caused this node to slide down slopes even if stop on slope was true (and there was downward velocity)
	# and for some reason had a bug when nearing the max floor angle, which caused this node to randomly shoot upwards at high speeds
	# also, if there was any side to side movement on a slope, move_and_slide_and_snap would cause this node to drift downards
	# the following is an alternative to move_and_slide, with extra functionality to avoid many inconsistencies in the physics engine
	for slide_count in range(max_slides):
		var friction_factor := 1.0
		
		if is_sliding_on_floor:
			# Check for friction on the floor
			var collider := floor_collision.collider
			
			if "physics_material_override" in collider and collider.physics_material_override != null:
				friction_factor = 1 - collider.physics_material_override.friction
		
		if is_sliding_on_wall:
			# Check for friction on the wall
			var collider := wall_collision.collider
			
			# (_slide_count != 0 or travel_vector.normalized().dot(wall_collision.normal) < 0) is to remove a bug where
			# if the friction is 1, track_wall is true, and the character is moving away from the wall,
			# the character will still be stuck to the wall
			if (slide_count != 0 or travel_vector.normalized().dot(wall_collision.normal) < 0) and "physics_material_override" in collider and collider.physics_material_override != null:
				friction_factor *= 1 - collider.physics_material_override.friction
		
		if is_zero_approx(friction_factor) or is_zero_approx(travel_vector.length()):
			break
		
		var collision = move_and_collide(travel_vector * friction_factor, infinite_inertia)
		
		if collision == null:
			break
		
		else:
			# We convert to CollisionData3D to make it mutable, and unique (otherwise additional calls to move_and_collide will modify previous instances of KinematicCollision)
			collision = CollisionData3D.new(collision, self)
			collision.travel /= friction_factor
			
			if not infinite_inertia and collision.collider is RigidBody and (not is_sliding_on_floor or (not is_sliding_on_wall and floor_collision.collider != collision.collider)):
				collision.collider.apply_impulse(collision.position - collision.collider.global_transform.origin, linear_velocity.project(collision.normal) * mass * delta)
			
			if collision.normal.angle_to(up_vector) < floor_max_angle:
				# FLOOR COLLISION HANDLING
				floor_collision = collision
					
				if is_sliding_on_floor:
					# If moving on a floor, and we hit another floor, rotate the movement_vector towards the up_vector such that the new vector is along the floor plane
					# This is better than just sliding the movement_vector as that can be deflected to the side
					var new_vector := up_vector.cross(travel_vector).cross(collision.normal).normalized()
					travel_vector = new_vector * (travel_vector - collision.travel).length()
					linear_velocity = new_vector * linear_velocity.length()
				
				else:
					# if we weren't on a floor, emit the landed signal
					is_sliding_on_floor = true
					var vertical_speed := linear_velocity.dot(up_vector)
					
					# check for bounce
					if "physics_material_override" in collision.collider and collision.collider.physics_material_override != null:
						travel_vector = _handle_bounce(collision, travel_vector)
					
					else:
						# otherwise just slide against the floor here
						linear_velocity = linear_velocity.slide(collision.normal)
						travel_vector = (travel_vector - collision.travel).slide(collision.normal)
					
					emit_signal("body_entered", collision.collider)
					emit_signal("landed", vertical_speed)
					# we recheck both because the signals might trigger those objects to disappear
					is_sliding_on_floor = is_on_floor()
					is_sliding_on_wall = is_on_wall()
			
			else:
				# WALL COLLISION HANDLING
				wall_collision = collision
				
				if is_sliding_on_floor and not _impulsing:
					# if we're on a floor, and we hit a wall, we correct the new movement_vector so that it doesn't move up the wall
					# such is the case for steep walls
					travel_vector -= collision.travel
					var corrected_normal: Vector3 = collision.normal.slide(up_vector).normalized()
					travel_vector = (travel_vector.slide(up_vector).normalized() * travel_vector.length()).slide(corrected_normal)
					linear_velocity = (linear_velocity.slide(up_vector).normalized() * linear_velocity.length()).slide(corrected_normal)
				
				# check for bounce if we're flying in the air and hit a wall
				elif "physics_material_override" in collision.collider and collision.collider.physics_material_override != null:
					travel_vector = _handle_bounce(collision, travel_vector)
				
				else:
					# otherwise just slide
					linear_velocity = linear_velocity.slide(collision.normal)
					travel_vector = (travel_vector - collision.travel).slide(collision.normal)
				
				if not is_sliding_on_wall:
					is_sliding_on_wall = true
					emit_signal("body_entered", collision.collider)
					emit_signal("touched_wall", linear_velocity.project(collision.normal))
					# we recheck both because the signals might trigger those objects to disappear
					is_sliding_on_floor = is_on_floor()
					is_sliding_on_wall = is_on_wall()
	
	# We check if the wall collision has been updated
	# If it's not been updated, then no wall was hit
	if wall_collision == tmp_wall_collision:
		wall_collision = null
	
	# floor tracking
	# If the floor collision did not change in this frame, it definitely means that no floor was touched
	# This is because floor_collision is not the collider itself but the collision data
	# If a new collision was made the data would update even if it's the same collider (things like position would change)
	# floor_collision could be null even if tmp_floor_collision wasn't if something happend during the "landed" signal (like jumping)
	if floor_collision == null or floor_collision == tmp_floor_collision:
		floor_collision = null

		if was_on_floor:
			if not _impulsing:
				# this is the adaptive floor snapping
				# checks in the direction of the last floor first
				var has_hit_floor := last_floor_collision != null
				var test_vector := (- last_floor_collision.normal) if has_hit_floor else down_vector

				if is_on_wall():
					test_vector = test_vector.slide(wall_collision.normal).normalized()

				var collision := move_and_collide(test_vector * snap_distance, infinite_inertia, true, true)

				# if there was no floor, and we used the last floor normal, check downwards
				if has_hit_floor and collision == null:
					if is_on_wall():
						test_vector = down_vector.slide(wall_collision.normal).normalized()

					else:
						test_vector = down_vector
					
					collision = move_and_collide(test_vector * snap_distance, infinite_inertia, true, true)

				# if it is a floor, move down to it and align the linear velocity to it
				if collision != null and collision.normal.angle_to(up_vector) < floor_max_angle:
					floor_collision = CollisionData3D.new(collision, self)
					linear_velocity = align_to_floor(linear_velocity)

					if not is_zero_approx(collision.travel.length()):
						global_transform.origin += collision.travel.project(test_vector)
				
				else:
					linear_velocity += floor_velocity
					floor_velocity = Vector3.ZERO
	
	# wall tracking
	# so that even if the character isn't moving but is next to a wall, wall_collision will still update
	if track_wall and not is_on_wall() and was_on_wall and last_wall_collision != null:
		var collision: KinematicCollision
		
		if is_on_floor():
			collision = move_and_collide(- last_wall_collision.normal.slide(floor_collision.normal).normalized() * get("collision/safe_margin"), infinite_inertia, true, true)
		
		else:
			collision = move_and_collide(- last_wall_collision.normal * get("collision/safe_margin"), infinite_inertia, true, true)
		
		if collision != null:
			if collision.normal.angle_to(up_vector) <= floor_max_angle:
				floor_collision = CollisionData3D.new(collision, self)
			
			else:
				wall_collision = CollisionData3D.new(collision, self)
	
	if is_on_floor():
		last_floor_collision = floor_collision
		
		if not infinite_inertia and floor_collision.collider is RigidBody:
			floor_collision.collider.apply_impulse(floor_collision.position - floor_collision.collider.global_transform.origin, down_vector * mass * gravity_acceleration * delta)
	
	else:
		linear_velocity += down_vector * gravity_acceleration * delta
	
	if is_on_wall():
		last_wall_collision = wall_collision


func _handle_bounce(collision: CollisionData3D, travel_vector: Vector3) -> Vector3:
	# Process bounce behaviours, which is exactly the same for floors and walls
	travel_vector -= collision.travel
	var factor: float
	
	if collision.collider.physics_material_override.absorbent:
		factor = 2 - collision.collider.physics_material_override.bounce
	
	else:
		factor = 1 + collision.collider.physics_material_override.bounce
	
	linear_velocity -= linear_velocity.project(collision.normal) * factor
	return travel_vector - travel_vector.project(collision.normal) * factor
