# Rotates the parent node to face the movement_vector from the target
class_name FaceMovement
extends Node


export var use_true_movement := true						# If true, the parent will face the direction the movement source is actually moving (useful when you want the character to face along the wall when sliding on it)
export var enable_pitch_rotation := false					# If true, the parent will be able to turn up and down to face the movement_vector
export(float, 0, 1) var interpolation_weight := 0.1			# If interpolation is not desired, set to 1
export var threshold := 0.05									# Will only rotate if the movement_vector is faster than this
export var always_rotate := true

var _last_movement_vector: Vector3
var _last_origin: Vector3


func get_new_basis(delta, current_transform: Transform, linear_velocity: Vector3) -> Basis:
	var tmp_vector: Vector3
	
	if use_true_movement:
		if delta == 0:
			return current_transform.basis
		
		var new_origin := current_transform.origin
		tmp_vector = (new_origin - _last_origin) / delta
		_last_origin = new_origin
	
	else:
		tmp_vector = linear_velocity
	
	if not enable_pitch_rotation:
		tmp_vector -= tmp_vector.project(current_transform.basis.y)		# Flatten the vector
	
	var speed := tmp_vector.length()
	if always_rotate:
		if speed <= threshold:
			tmp_vector = _last_movement_vector
		
		else:
			# only update last movement vector if the new movement vector is nonzero
			_last_movement_vector = tmp_vector
	
	if speed > threshold:
		var transform: Transform = current_transform.looking_at(current_transform.origin + tmp_vector, Vector3.UP)
		
		return current_transform.interpolate_with(transform, interpolation_weight).basis
	
	return current_transform.basis
