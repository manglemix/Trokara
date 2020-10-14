# Adds dual jump functionality to the parent character
# If jumping is set to true for a moment, the character will jump to the initial_jump_height
# If jumping is set to true until the highest point of the jump, the height will be the full_jump_height
class_name CharacterJump
extends Node


signal jumped		# emitted as soon as jumping is set from false to true
signal falling		# emitted as soon as jumping is set from true to false

# The maximum height of the jump if the spacebar is tapped once
export var initial_jump_height: float setget set_initial_jump_height

# The maximum height of the jump if the spacebar is held down all the way (aka the "hold" jump)
export var full_jump_height: float setget set_full_jump_height

# A small period of time after falling in which you can still jump
export var coyote_time := 0.1

# The velocity applied on the initial jump
var initial_velocity setget set_initial_velocity

# The duration of the "hold" jump
# The end of this time should be when the vertical velocity is zero
var jump_time: float setget set_jump_time

# The acceleration applied during the "hold" jump
var acceleration: float setget set_acceleration

# if set from false to true, the character will jump, otherwise it will stop any acceleration and begin falling
var jumping := false setget set_jumping

# How much time there is left for the full jump
var _current_jump_time: float

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
	if value != jumping:
		set_physics_process(value)
		jumping = value
		
		var impulse = initial_velocity
		
		if character.get_vertical_speed() < 0:
			impulse -= character.linear_velocity.project(character.up_vector)
		
		if value:
			character.apply_impulse(impulse)
			_current_jump_time = jump_time
			emit_signal("jumped")
		
		else:
			emit_signal("falling")


func _ready():
	set_physics_process(false)


func _physics_process(delta):
	if _current_jump_time <= 0:
		set_jumping(false)
	
	_current_jump_time -= delta
	character.linear_velocity += character.up_vector * acceleration * delta
