# EXtends the character script to have more natural movement through interpolation
# Also adds air strafing, which limits the air speed so there is no net acceleration
class_name ClassicCharacter2D
extends Character2D


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0


func _integrate_movement(vector: Vector2, delta: float) -> Vector2:
	if is_on_floor():
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		if vector.length() >= linear_velocity.length():
			return linear_velocity.linear_interpolate(align_to_floor(vector), acceleration_weight * delta)
			
		else:
			return linear_velocity.linear_interpolate(align_to_floor(vector), brake_weight * delta)
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var speed := linear_velocity.length()
		var new_velocity := linear_velocity + vector * delta
		return new_velocity.normalized() * speed
