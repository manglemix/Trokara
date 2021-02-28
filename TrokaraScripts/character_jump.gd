class_name CharacterJump
extends Node


signal jumped		# emitted as soon as jumping is set from false to true
signal falling		# emitted as soon as jumping is set from true to false

# The maximum height of the jump if the spacebar is tapped once
export var initial_jump_height: float setget set_initial_jump_height

# The maximum height of the jump if the spacebar is held down all the way (aka the "hold" jump)
export var full_jump_height: float setget set_full_jump_height

# The number of jumps possible in the air
export var extra_jumps := 1 setget set_extra_jumps

# A small period of time after falling in which you can still jump
export var coyote_time := 0.1

# If true, velocity will be set instead of added to, allowing for more traditional platformer movement
export var absolute_impulse := true

# if true, the initial_speed will move towards the character's movement_vector, when jumping in the air
export var deform_to_movement := true

# this value is multiplied with the movement_vector to determine how much the initial_speed is deformed/skewed
export var deformation_factor := 1.0

# if true, the initial jump would be along the floor normal
export var use_floor_normal := true

# if true, will jump up along the character's up vector, otherwise will just jump along the character's y vector
export var use_up_vector := false

# the maximum angle from the up vector that the initial impulse can be deflected by
export var max_deflection_angle_degrees := 45.0 setget set_max_deflection_angle_degrees

# the angle between the initial impulse (after clamping the angle) and the up vector will be multiplied with this
# this is to reduce the amount of deflection caused by the floor normal
export var floor_angle_factor := 0.5

# if true, the character can jump from steep slopes, even if the character cannot walk on it
# also allows jumps to reset on slopes
export var jump_off_wall := false

# if true, the velocity of the floor the character is on will be added to the linear velocity when jumping
export var include_floor_velocity := true

# The velocity applied on the initial jump
var initial_speed: float setget set_initial_speed

# The duration of the "hold" jump
# The end of this time should be when the vertical velocity is zero
var jump_time: float setget set_jump_time

# The remaining amount of time left for the character to glide up to the full jump height
var current_jump_time: float

# The acceleration applied during the "hold" jump
var acceleration: float setget set_acceleration

# if set from false to true, the character will jump, otherwise it will stop any acceleration and begin falling
var jumping := false setget set_jumping

# the radian counterpart
var max_deflection_angle := PI / 4 setget set_max_deflection_angle

# True if the character jumped off the floor, until the character lands
# needed to prevent the character from jumping multiple times within the coyote time
var initial_jumped := false

# current number of jumps
onready var current_jumps := extra_jumps

# no type hint as character can be 2D or 3D
onready var character := get_parent()


func set_extra_jumps(value: int) -> void:
	extra_jumps = value
	
	# If extra jumps is changed, the current jumps need to be updated
	# However, they only get updated as soon as the floor is touched (or wall),
	# thus we check here
	if character != null and (character.is_on_floor() or (jump_off_wall and character.is_on_wall())):
		current_jumps = value


func set_initial_jump_height(height: float) -> void:
	if character == null:
		yield(self, "ready")
	
	initial_jump_height = height
	initial_speed = sqrt(2 * character.gravity_acceleration * height)


func set_full_jump_height(height: float) -> void:
	if character == null:
		yield(self, "ready")
	
	# Solves for jump time and acceleration using the height given
	full_jump_height = height
	acceleration = character.gravity_acceleration - initial_speed * initial_speed / 2 / height
	jump_time = initial_speed / (character.gravity_acceleration - acceleration)


func set_initial_speed(speed: float) -> void:
	if character == null:
		yield(self, "ready")
	
	initial_speed = speed
	initial_jump_height = speed * speed / 2 / character.gravity_acceleration


func set_jump_time(value: float) -> void:
	jump_time = value
	acceleration = character.gravity_acceleration - initial_speed / jump_time
	full_jump_height = jump_time * (initial_speed + (character.gravity_acceleration - acceleration) / 2 * jump_time)


func set_acceleration(value: float) -> void:
	if value < character.gravity_acceleration:
		acceleration = value
		full_jump_height = jump_time * (initial_speed + (character.gravity_acceleration - value) / 2 * jump_time)
	
	else:
		# the character would just continue accelerating upwards
		push_error("jump acceleration is higher than gravity!")


func set_max_deflection_angle_degrees(value: float) -> void:
	max_deflection_angle_degrees = value
	max_deflection_angle = deg2rad(value)


func set_max_deflection_angle(value: float) -> void:
	max_deflection_angle = value
	max_deflection_angle_degrees = rad2deg(value)


func set_jumping(value: bool) -> void:
	if value == jumping:
		return
	
	if value:
		var system_time := OS.get_system_time_msecs()
		
		# if true, the floor can be jumped off of
		var use_floor: bool = character.last_floor_collision != null and (system_time - character.last_floor_collision.collision_time) / 1000.0 <= coyote_time
		
		# if true, the character is still on a floor or wall, and hasn't jumped
		var jump_off_surface: bool = not initial_jumped and \
		(use_floor or jump_off_wall and character.last_wall_collision != null and (system_time - character.last_wall_collision.collision_time) / 1000.0 <= coyote_time)
		
		if jump_off_surface or current_jumps > 0:
			var up_vector = character.up_vector if use_up_vector else character.global_transform.basis.y.normalized()
			var initial_vector
			
			if jump_off_surface:
				initial_jumped = true
				
				if use_floor_normal:
					var normal
					
					if use_floor:
						normal = character.last_floor_collision.normal.normalized()
					
					else:
						normal = character.last_wall_collision.normal.normalized()
					
					var angle: float = abs(up_vector.angle_to(normal))
					
					if is_zero_approx(angle):
						initial_vector = up_vector
						
					elif angle <= max_deflection_angle:
						initial_vector = up_vector.slerp(normal, floor_angle_factor)
					
					else:
						initial_vector = up_vector.slerp(normal, max_deflection_angle / angle * floor_angle_factor)
				
				else:
					initial_vector = up_vector
				
			else:
				initial_vector = up_vector
				current_jumps -= 1
			
			character.temporary_unsnap()	# disable floor snapping
			
			if absolute_impulse:
				character.linear_velocity = initial_speed * initial_vector
			
			else:
				character.linear_velocity = character.linear_velocity.slide(up_vector) + initial_speed * initial_vector
			
			if deform_to_movement:
				character.linear_velocity += character.movement_vector.slide(up_vector).normalized() * character.movement_vector.length() * deformation_factor
			
			if include_floor_velocity:
				character.linear_velocity += character.floor_velocity
			
			current_jump_time = jump_time
			emit_signal("jumped")
			set_process(true)
			jumping = true
	
	else:
		emit_signal("falling")
		set_process(false)
		jumping = false


func _ready():
	# warning-ignore-all:return_value_discarded
	character.connect("landed", self, "_handle_landed")
	character.connect("touched_wall", self, "_handle_touched_wall")
	set_process(false)


func _handle_landed(_speed) -> void:
	current_jumps = extra_jumps
	initial_jumped = false


func _handle_touched_wall(_vec) -> void:
	if jump_off_wall:
		current_jumps = extra_jumps
		initial_jumped = false


func _process(delta):
	character.linear_velocity += acceleration * (character.up_vector if use_up_vector else character.global_transform.basis.y.normalized()) * delta
	current_jump_time -= delta
	
	if current_jump_time <= 0:
		set_jumping(false)
