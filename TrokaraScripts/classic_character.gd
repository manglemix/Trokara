# EXtends the character script to have more natural movement through interpolation
# Also adds air strafing, which limits the air speed so there is no net acceleration
class_name ClassicCharacter
extends Character


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0


func _integrate_movement(vector: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		var new_speed := vector.length()
		var speed := linear_velocity.length()
		
		if not is_zero_approx(new_speed):
		# These 2 lines are to always have the linear_velocity point along the vector
		# So that when transitioning between slopes will not affect the speed
		# Which tends to happen because we are interpolating in between
			linear_velocity = vector.normalized() * speed
		
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		if new_speed >= speed:
			return linear_velocity.linear_interpolate(vector, acceleration_weight * delta)
			
		else:
			return linear_velocity.linear_interpolate(vector, brake_weight * delta)
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var speed := linear_velocity.length()
		var new_velocity := linear_velocity + vector * delta
		return new_velocity.normalized() * speed
