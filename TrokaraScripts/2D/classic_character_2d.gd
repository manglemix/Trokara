# EXtends the character script to have more natural movement through interpolation
# Also adds air strafing, which limits the air speed so there is no net acceleration
class_name ClassicCharacter2D
extends Character2D


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


func _integrate_movement(vector: Vector2, delta: float) -> Vector2:
	if is_on_floor():
		# Use acceleration_weight for speeding up, and use brake_weight for slowing down
		var new_velocity := linear_velocity.linear_interpolate(align_to_floor(vector), 1.0 - exp(- (acceleration_weight if vector.length() >= linear_velocity.length() else brake_weight) * delta))
		
		if enable_slope_resistance:
			return new_velocity * (1 - clamp((floor_collision[SerialEnums.NORMAL].angle_to(up_vector) - min_resistance_angle) / (floor_max_angle - min_resistance_angle) * resistance_factor, 0, 1))
		
		return new_velocity
	
	else:
		# this will allow the linear_velocity to be modified, without changing its magnitude
		var vertical_velocity := linear_velocity.project(up_vector)
		return (linear_velocity - vertical_velocity).linear_interpolate(align_to_floor(vector), 1.0 - exp(- air_weight * delta)) + vertical_velocity
