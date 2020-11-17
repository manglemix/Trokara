# Adds dual jump functionality to the parent character
# If jumping is set to true, then false, the character will jump to the initial_jump_height
# If jumping is just set to true, the height will be the full_jump_height
class_name CharacterJump
extends Node


signal jumped		# emitted as soon as jumping is set from false to true
signal falling		# emitted as soon as jumping is set from true to false

# The maximum height of the jump if the spacebar is tapped once
export var initial_jump_height: float setget set_initial_jump_height

# The maximum height of the jump if the spacebar is held down all the way (aka the "hold" jump)
export var full_jump_height: float setget set_full_jump_height

# The number of jumps possible in the air
export var extra_jumps := 1

# A small period of time after falling in which you can still jump
export var coyote_time := 0.1

# if true, the initial_velocity will move towards the character's movement_vector, when jumping in the air
export var deform_to_movement := true

# this value is multiplied with the movement_vector to determine how much the initial_velocity is deformed/skewed
export var deformation_factor := 1.0

# The velocity applied on the initial jump
var initial_velocity setget set_initial_velocity

# The duration of the "hold" jump
# The end of this time should be when the vertical velocity is zero
var jump_time: float setget set_jump_time

# The acceleration applied during the "hold" jump
var acceleration: float setget set_acceleration

# if set from false to true, the character will jump, otherwise it will stop any acceleration and begin falling
var jumping := false setget set_jumping

# current number of jumps
var current_jumps := 0

# How much time there is left for the full jump
var _current_jump_time: float

# True if the character jumped off the floor, until the character lands
# needed to prevent the character from jumping multiple times within the coyote time
var _initial_jumped := false


# no type hint as character can be 2D or 3D
onready var character := get_parent()


func set_initial_jump_height(height: float) -> void:
	if not is_instance_valid(character):
		yield(self, "ready")
	
	initial_jump_height = height
	# sets the new initial_velocity to be the same direction as the last initial_velocity
	if initial_velocity == null or is_zero_approx(initial_velocity.length_squared()):
		# If the initial_velocity is empty (all values are 0), then a new vector pointing straight up
		initial_velocity = character.up_vector * sqrt(2 * character.gravity_acceleration * height)
		
	else:
		# scales the last initial_velocity according to its vertical component
		initial_velocity *= sqrt(2 * character.gravity_acceleration * height) / character.up_vector.dot(initial_velocity)


func set_full_jump_height(height: float) -> void:
	if not is_instance_valid(character):
		yield(self, "ready")
	
	# Solves for jump time using the height given
	# Assumes that initial_speed ^ 2 / 2 (gravity - acceleration) = height
	# and jump_time = initial_speed / (gravity - acceleration)
	full_jump_height = height
	var initial_speed: float = character.up_vector.dot(initial_velocity)
	acceleration = character.gravity_acceleration - pow(initial_speed, 2) / 2 / height
	jump_time = initial_speed / (character.gravity_acceleration - acceleration)


func set_initial_velocity(velocity) -> void:
	initial_velocity = velocity
	initial_jump_height = pow(character.up_vector.dot(velocity), 2) / 2 / character.gravity_acceleration


func set_jump_time(value: float) -> void:
	set_full_jump_height(character.up_vector.dot(initial_velocity) * value / 2)


func set_acceleration(value: float) -> void:
	if value < character.gravity_acceleration:
		set_full_jump_height(pow(character.up_vector.dot(initial_velocity), 2) / (character.gravity_acceleration - value) / 2)
	
	else:
		push_error("jump acceleration is higher than gravity!")


func set_jumping(value: bool) -> void:
	if value:
		if character.air_time < coyote_time or current_jumps > 0:
			if not _initial_jumped and character.air_time < coyote_time:
				_initial_jumped = true
			
			else:
				current_jumps -= 1
			
			var impulse
			if deform_to_movement and not character.is_on_floor():
				# The impulse vector consists of the initial_velocity added with the flattened movement_vector
				impulse = initial_velocity + character.movement_vector.slide(character.up_vector).normalized() * character.movement_vector.length() * deformation_factor
				# this rescales the impluse so that the vertical speed is equal to initial_velocity's vertical speed
				impulse *= initial_velocity.dot(character.up_vector) / impulse.dot(character.up_vector)
			
			else:
				impulse = initial_velocity
			
			if character.is_on_floor():
				character.apply_impulse(impulse)
			
			else:
				character.linear_velocity = impulse
			
			_current_jump_time = jump_time
			emit_signal("jumped")
		
		else:
			return
		
	elif jumping:
		emit_signal("falling")
	
	set_physics_process(value)
	jumping = value


func _ready():
	# warning-ignore:return_value_discarded
	set_physics_process(false)
	character.connect("landed", self, "_reset_jumps")


func _physics_process(delta):
	if _current_jump_time <= 0:
		set_jumping(false)
	
	_current_jump_time -= delta
	character.linear_velocity += character.up_vector * acceleration * delta


func jump_to(height: float) -> void:
	# sets jumping to true until the target height is reached, or the apex of the jump is reached
	# if height is set to below initial_jump_height, the character wil lstill jump to the initial_jump_height
	var a := acceleration
	var b: float = 2 * initial_velocity.dot(character.up_vector)
	var c := - 2 * (height - initial_jump_height)
	var t := (- b + sqrt(b * b - 4 * a * c)) / 2 / a
	
	set_jumping(true)
	
	if t <= jump_time:
		if t > 0:
			yield(get_tree().create_timer(t), "timeout")
		
		set_jumping(false)


func _reset_jumps(_vertical_speed) -> void:
	current_jumps = extra_jumps
	_initial_jumped = false
