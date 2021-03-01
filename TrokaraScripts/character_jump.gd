class_name CharacterJump
extends Node


signal jumped		# emitted as soon as jumping is set from false to true
signal falling		# emitted as soon as jumping is set from true to false

# The maximum height of the jump if the spacebar is tapped once
export var initial_jump_height: float

# The maximum height of the jump if the spacebar is held down all the way (aka the "hold" jump)
export var full_jump_height: float

# The number of jumps possible in the air
export var extra_jumps := 1 setget set_extra_jumps

# A small period of time after falling in which you can still jump
export var coyote_time := 0.1

# the maximum angle from the up vector that the initial impulse can be deflected by
export var max_deflection_angle_degrees := 45.0 setget set_max_deflection_angle_degrees

# the angle between the initial impulse (after clamping the angle) and the up vector will be multiplied with this
# this is to reduce the amount of deflection caused by the floor normal
export var floor_angle_factor := 0.5

# The velocity applied on the initial jump
var initial_speed: float

# The duration of the "hold" jump
# The end of this time should be when the vertical velocity is zero
var jump_time: float

# The remaining amount of time left for the character to glide up to the full jump height
var current_jump_time: float

# The acceleration applied during the "hold" jump
var acceleration: float

# if set from false to true, the character will jump, otherwise it will stop any acceleration and begin falling
var jumping := false

# the radian counterpart
var max_deflection_angle := PI / 4 setget set_max_deflection_angle

# True if the character jumped off the floor, until the character lands
# needed to prevent the character from jumping multiple times within the coyote time
var initial_jumped := false

# current number of jumps
onready var current_jumps := extra_jumps


func set_extra_jumps(value: int) -> void:
	extra_jumps = value
	current_jumps = value


func calculate_jump_specifics(gravity_acceleration: float) -> void:
	initial_speed = sqrt(2 * gravity_acceleration * initial_jump_height)
	acceleration = gravity_acceleration - initial_speed * initial_speed / 2 / full_jump_height
	jump_time = initial_speed / (gravity_acceleration - acceleration)


func change_initial_speed(speed: float, gravity_acceleration: float) -> void:
	initial_speed = speed
	initial_jump_height = speed * speed / 2 / gravity_acceleration


func change_jump_time(value: float, gravity_acceleration: float) -> void:
	jump_time = value
	acceleration = gravity_acceleration - initial_speed / jump_time
	full_jump_height = jump_time * (initial_speed + (gravity_acceleration - acceleration) / 2 * jump_time)


func change_acceleration(value: float, gravity_acceleration: float) -> void:
	if value < gravity_acceleration:
		acceleration = value
		full_jump_height = jump_time * (initial_speed + (gravity_acceleration - value) / 2 * jump_time)
	
	else:
		# the character would just continue accelerating upwards
		push_error("jump acceleration is higher than gravity!")


func set_max_deflection_angle_degrees(value: float) -> void:
	max_deflection_angle_degrees = value
	max_deflection_angle = deg2rad(value)


func set_max_deflection_angle(value: float) -> void:
	max_deflection_angle = value
	max_deflection_angle_degrees = rad2deg(value)


func reset_jumps(_null) -> void:
	# the _null argument is just for convenience when connecting to signals in the Character script
	current_jumps = extra_jumps
	initial_jumped = false


func can_jump_off_surface(surface_collision: CollisionData3D) -> bool:
	return not initial_jumped and surface_collision != null and (OS.get_system_time_msecs() - surface_collision.collision_time) / 1000.0 <= coyote_time


func jump(up_vector, is_on_surface:=true, surface_normal=null):
	var initial_vector
	
	if is_on_surface:
		initial_jumped = true
		
		if surface_normal != null:
			var angle: float = abs(up_vector.angle_to(surface_normal))
			
			if is_zero_approx(angle):
				initial_vector = up_vector
				
			elif angle <= max_deflection_angle:
				initial_vector = up_vector.slerp(surface_normal, floor_angle_factor)
			
			else:
				initial_vector = up_vector.slerp(surface_normal, max_deflection_angle / angle * floor_angle_factor)
		
		else:
			initial_vector = up_vector
	
	else:
		initial_vector = up_vector
		current_jumps -= 1
	
	current_jump_time = jump_time
	emit_signal("jumped")
	jumping = true
	
	return initial_vector * initial_speed


func process_acceleration(up_vector, delta):
	current_jump_time -= delta
	
	if current_jump_time <= 0:
		end_jump()
	
	return acceleration * up_vector * delta


func end_jump() -> void:
	jumping = false
	emit_signal("falling")
