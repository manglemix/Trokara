# Adds jump functionality to the parent character, whilst providing a convenient interface for both users and AI to use
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

# Allows the player to jump even if not on the ground, if the character lands within this amount of time
export var jump_buffer := 0.1

# If true, input processing will be enabled
export var accept_input := false setget set_accept_input

# The velocity applied on the initial jump
var initial_velocity: Vector3 setget set_initial_velocity

# The duration of the "hold" jump
# The end of this time should be when the vertical velocity is zero
var jump_time: float setget set_jump_time

# The acceleration applied during the "hold" jump
var acceleration: float setget set_acceleration

# if set from false to true, the character will jump, otherwise it will stop any acceleration and begin falling
var jumping := false setget set_jumping

# How much time there is left for the full jump
var _current_jump_time: float

onready var character: Character = get_parent()


func set_initial_jump_height(height: float) -> void:
	if not is_instance_valid(character):
		yield(self, "ready")
	
	initial_jump_height = height
	# sets the new initial_velocity to be the same direction as the last initial_velocity
	if is_zero_approx(initial_velocity.length_squared()):
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
	var initial_speed_squared := pow(character.up_vector.dot(initial_velocity), 2)
	acceleration = character.gravity_acceleration - initial_speed_squared / 2 / height
	jump_time = sqrt(initial_speed_squared) / (character.gravity_acceleration - acceleration)


func set_accept_input(value: bool) -> void:
	accept_input = value
	set_process_input(value)


func set_initial_velocity(velocity: Vector3) -> void:
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
		if value:
			emit_signal("jumped")
			character.apply_impulse(initial_velocity)
			_current_jump_time = jump_time
		
		else:
			emit_signal("falling")
		
		set_physics_process(value)
		jumping = value


func _ready():
	# have to call again as calling set_process_input before _ready does nothing
	set_accept_input(accept_input)
	set_physics_process(false)


func _input(event):
	if event.is_action_pressed("jump"):
		if character.air_time < coyote_time:
			set_jumping(true)
		
		else:
			# This is the jump buffer code
			# If the character is in the air, wait until it lands, then check the difference in time
			var _last_jump_query := OS.get_system_time_msecs()
			yield(character, "landed")
			if (OS.get_system_time_msecs() - _last_jump_query) / 1000.0 <= jump_buffer:
				set_jumping(true)


func _physics_process(delta):
	if _current_jump_time <= 0 or (accept_input and not Input.is_action_pressed("jump")):
		set_jumping(false)
	
	_current_jump_time -= delta
	character.linear_velocity += character.up_vector * acceleration * delta
