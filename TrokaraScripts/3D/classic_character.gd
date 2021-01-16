# Extends the character script to have more natural movement through interpolation
# Also adds air strafing, which also prevents infinite speeds
class_name ClassicCharacter
extends Character


export(float, 0, 1000) var acceleration_weight := 12.0				# weight used to interpolate velocity to the movement vector
export(float, 0, 1000) var brake_weight := 18.0						# weight used to interpolate velocity to 0
export(float, 0, 1000) var air_weight := 2.0				# weight used to interpolate air velocity
export var enable_slope_resistance := true			# if enabled, movement up a steep slope will be slower
export(float, 0, 1) var resistance_factor := 0.7	# how much the angle of the slope will slow down (1 is complete resistance)

# the minimum angle after which movement up the slope will be reduced
export(float, 0, 90) var min_resistance_angle_degrees := 35.0 setget set_min_resistance_angle_degrees

# the radian counterpart
var min_resistance_angle := deg2rad(35) setget set_min_resistance_angle


func set_min_resistance_angle_degrees(value: float) -> void:
	min_resistance_angle_degrees = value
	min_resistance_angle = deg2rad(value)


func set_min_resistance_angle(value: float) -> void:
	min_resistance_angle = value
	min_resistance_angle_degrees = rad2deg(value)


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
		var new_velocity := linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- (acceleration_weight if vector.length() >= linear_velocity.length() else brake_weight) * delta))
		
		if enable_slope_resistance and new_velocity.normalized().dot(up_vector) > 0:
			var cross_vector := up_vector.cross(floor_collision[SerialEnums.NORMAL]).normalized()
			if cross_vector.is_normalized():
				var slided_vector := new_velocity.slide(cross_vector)
				return new_velocity - slided_vector * clamp((floor_collision[SerialEnums.NORMAL].angle_to(up_vector) - min_resistance_angle) / (floor_max_angle - min_resistance_angle) * resistance_factor, 0, 1)
		
		return new_velocity
	
	else: 
		# instead of interpolating the linear_velocity directly, this code only interpolates the non vertical component of linear_velocity
		var vertical_velocity := linear_velocity.project(up_vector)
		return special_lerp(linear_velocity - vertical_velocity, align_to_floor(vector), 1.0 - exp(- air_weight * delta)) + vertical_velocity
