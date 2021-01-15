# Extends the character script to have more natural movement through interpolation
# Also adds air strafing, which also prevents infinite speeds
class_name ClassicCharacter
extends Character


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0
export var air_weight := 2.0				# weight used to interpolate air velocity


static func special_lerp(from: Vector3, to: Vector3, weight: float, min_length:=-1.0) -> Vector3:
	# A special lerp function which rotates and resizes the from vector seperately
	# So that even if from and to are the same length, lerping from to to will not shorten then vector (which happens when lerped)
	# If min_length is less than 0, the returned vector will not be shorter than from vector
	# otherwise, the returned vector won't be shorter than min_length
	var from_length := from.length()
	var to_length := to.length()
	
	if min_length < 0:
		min_length = from_length
	
	if is_zero_approx(from_length):
		return to * weight
	
	if is_zero_approx(to_length):
		return from * (1 - weight)

	return from.normalized().slerp(to.normalized(), weight).normalized() * clamp(lerp(from_length, to_length, weight), min_length, to_length)


func _integrate_movement(vector: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		return linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- (acceleration_weight if vector.length() >= linear_velocity.length() else brake_weight) * delta))
	
	else: 
		# instead of interpolating the linear_velocity directly, this code only interpolates the non vertical component of linear_velocity
		var vertical_velocity := linear_velocity.project(up_vector)
		return special_lerp(linear_velocity - vertical_velocity, align_to_floor(vector), 1.0 - exp(- air_weight * delta)) + vertical_velocity
