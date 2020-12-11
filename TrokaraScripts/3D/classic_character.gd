# Extends the character script to have more natural movement through interpolation
# Also adds air strafing, which also prevents infinite speeds
class_name ClassicCharacter
extends Character


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0
export var strafe_weight := 2.0


func _integrate_movement(vector: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		if vector.length() >= linear_velocity.length():
			return linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- acceleration_weight * delta))
			
		else:
			return linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- brake_weight * delta))
	
	else:
		# instead of interpolating the linear_velocity directly, this code only interpolates the non vertical component of linear_velocity
		var vertical_velocity := linear_velocity.project(up_vector)
		return (linear_velocity - vertical_velocity).linear_interpolate(align_to_floor(vector), 1.0 - exp(- strafe_weight * delta)) + vertical_velocity
