# Extends the character script to have more natural movement through interpolation
# Also adds air strafing, which limits the air speed so there is no net acceleration
class_name ClassicCharacter
extends Character


export var acceleration_weight := 12.0		# weight used to interpolate velocity to the movement vector
export var brake_weight := 18.0				# weight used to interpolate velocity to 0


func _integrate_movement(vector: Vector3, delta: float) -> Vector3:
	if is_on_floor():
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		if vector.length() >= linear_velocity.length():
			return linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- acceleration_weight * delta))
			
		else:
			return linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- brake_weight * delta))
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var cross_product := up_vector.cross(vector).normalized()
		if cross_product.is_normalized():
			# essentially, we rotate and resize the vector such that it is identical to the linear velocity, except its direction may be different
			var corrected_vector := up_vector.rotated(cross_product, up_vector.angle_to(linear_velocity)) * linear_velocity.length()
			# so then we just interpolate between to change direction without altering magnitude
			return linear_velocity.linear_interpolate(corrected_vector, 1.0 - exp(- acceleration_weight * delta))
		
		return linear_velocity
