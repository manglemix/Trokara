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
		var tmp_velocity := linear_velocity
		
		if not is_zero_approx(new_speed):
			# This will turn the linear_velocity such that it has the same angle of depression as the movement_vector
			# This is so that downwaed angles are not interpolated (which would cause varying speeds when transitioning between slopes)
			# But will still allow interpolation when the two vectors are pointing in different directions
			tmp_velocity += vector.project(down_vector) * speed / new_speed - tmp_velocity.project(down_vector)
		
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		if new_speed >= speed:
			return tmp_velocity.linear_interpolate(vector, acceleration_weight * delta)
			
		else:
			return tmp_velocity.linear_interpolate(vector, brake_weight * delta)
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var speed := linear_velocity.length()
		var new_velocity := linear_velocity + vector * delta
		return new_velocity.normalized() * speed
