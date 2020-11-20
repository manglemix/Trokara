# A GTA style arm for cameras
# Will only shorten the arm if the end is intersecting an obstacle
# So the arm can intersect small obstacles without shortening
class_name KinematicArm
extends Spatial


export var collider_shape: Shape setget set_collider_shape
export var current_length := 5.0
export var min_length := 0.0
export var target_length := 5.0
export var weight := 10.0
export var max_slope_angle_degrees := 45.0 setget set_max_slope_angle_degrees
export(Array, NodePath) var _exclude_paths: Array
export(int, LAYERS_3D_PHYSICS) var collision_mask := 1 setget set_collision_mask

var kinematic_body: KinematicBody
var max_slope_angle := PI / 4 setget set_max_slope_angle


func set_max_slope_angle_degrees(value: float) -> void:
	max_slope_angle_degrees = value
	max_slope_angle = deg2rad(value)


func set_max_slope_angle(value: float) -> void:
	max_slope_angle = value
	max_slope_angle_degrees = rad2deg(value)


func set_collider_shape(shape: Shape) -> void:
	collider_shape = shape
	
	if is_instance_valid(kinematic_body):
		if kinematic_body.get_child_count() > 0:
			kinematic_body.get_child(0).queue_free()
		
		var collision_shape := CollisionShape.new()
		collision_shape.shape = shape
		kinematic_body.add_child(collision_shape)


func set_collision_mask(mask: int) -> void:
	collision_mask = mask
	
	if is_instance_valid(kinematic_body):
		kinematic_body.collision_mask = mask


func _enter_tree():
	kinematic_body = KinematicBody.new()
	kinematic_body.collision_layer = 0
	kinematic_body.collision_mask = collision_mask
	set_collider_shape(collider_shape)
	kinematic_body.name = name + "KinematicBody"
	
	for path in _exclude_paths:
		kinematic_body.add_collision_exception_with(get_node(path))
	
	get_tree().current_scene.call_deferred("add_child", kinematic_body)
	yield(kinematic_body, "ready")
	set_physics_process(true)


func _exit_tree():
	kinematic_body.queue_free()
	set_physics_process(false)


func _ready():
	set_physics_process(false)


func _physics_process(delta):
	current_length = lerp(current_length, target_length, weight * delta)
	var collision_info := _move_kinematic_body()
	
	if is_instance_valid(collision_info):
		if collision_info.normal.angle_to(- global_transform.basis.z) <= max_slope_angle:
			_reset_kinematic_body()
		
		else:
			var relative_origin := global_transform.origin - kinematic_body.global_transform.origin
			var arm_vector := - global_transform.basis.z * current_length
			var perpendicular_arm_length := arm_vector.dot(collision_info.normal)
			var perpendicular_distance := collision_info.normal.dot(relative_origin)
			var ratio := abs(perpendicular_distance / perpendicular_arm_length)
			var correction_vector := arm_vector.slide(collision_info.normal) * ratio + relative_origin.slide(collision_info.normal)
			
			if correction_vector.dot(arm_vector) > 0:
				_reset_kinematic_body()
			
			else:
				# warning-ignore:return_value_discarded
				kinematic_body.move_and_collide(correction_vector)
				current_length *= ratio
				_update_children()
	
	else:
		_update_children()


func _update_children() -> void:
	var target := kinematic_body.global_transform.origin
	for child in get_children():
		child.global_transform.origin = target


func _move_kinematic_body(length:=current_length) -> KinematicCollision:
	return kinematic_body.move_and_collide(- global_transform.basis.z * length + global_transform.origin - kinematic_body.global_transform.origin)


func _reset_kinematic_body() -> void:
	kinematic_body.global_transform.origin = - global_transform.basis.z * min_length + global_transform.origin
