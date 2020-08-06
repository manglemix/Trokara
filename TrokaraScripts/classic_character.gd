# EXtends the character script to have more natural movement through interpolation
# Also adds air strafing, which limits the air speed so there is no net acceleration
class_name ClassicCharacter
extends Character


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0


func _integrate_movement(vector: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		if is_zero_approx(vector.length_squared()):
			return linear_velocity * (1 - brake_weight * delta)
		else:
			return linear_velocity.linear_interpolate(vector, acceleration_weight * delta)
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var original_length := linear_velocity.length()
		var new_velocity := linear_velocity + vector * delta
		return new_velocity.normalized() * original_length
