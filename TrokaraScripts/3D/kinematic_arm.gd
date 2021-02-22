# A GTA style arm for cameras
# Will only shorten the arm if the end is intersecting an obstacle
# So the arm can intersect small obstacles without shortening
# NOTE, the end of the arm extends out from the - z axis
class_name KinematicArm
extends Spatial


# The shape of thet end of the arm
export var collider_shape: Shape setget set_collider_shape

# the initial length of the arm
export var current_length := 5.0

# the closest the end of the arm can be to the origin of this node
export var min_length := 0.0

# the length the arm will try to extend to
export var target_length := 5.0

# the weight used when interpolating the arm's length
export var weight := 10.0

# paths to objects which the arm won't collide with
# WARNING, modifying after _ready has no effect, add excludes directly to kinematic_body
export(Array, NodePath) var _exclude_paths: Array

# the layers which the end of the arm will collide with
export(int, LAYERS_3D_PHYSICS) var collision_mask := 1 setget set_collision_mask

var kinematic_body: KinematicBody


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
	# every time the arm enters the tree, a new kinematic body is made
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
	# every time the kinematic body exits the tree, the kinematic body is freed too
	kinematic_body.queue_free()
	set_physics_process(false)


func _ready():
	set_physics_process(false)


func _physics_process(delta):
	current_length = lerp(current_length, target_length, weight * delta)
	var collision_info := _move_kinematic_body()
	
	if is_instance_valid(collision_info):
		var relative_origin := global_transform.origin - kinematic_body.global_transform.origin
		var arm_vector := - global_transform.basis.z * current_length
		var perpendicular_arm_length := arm_vector.dot(collision_info.normal)		# perpendicular length of the arm to the wall
		var perpendicular_distance := collision_info.normal.dot(relative_origin)	# perpendicular length of the part of the arm outside the wall
		
		if perpendicular_arm_length == 0:
			_reset_kinematic_body()
			
		else:
			var ratio := abs(perpendicular_distance / perpendicular_arm_length)			# this is used to resize the arm such that the new end is outside the wall
			# this vector moves the kinematic obdy along the wall to reach the intersection point of the arm
			var correction_vector := arm_vector.slide(collision_info.normal) * ratio + relative_origin.slide(collision_info.normal)
			
			if correction_vector.dot(arm_vector) > 0:
				# if the arm is moving away from the origin, reset
				_reset_kinematic_body()
				return
			
			else:
				# warning-ignore:return_value_discarded
				kinematic_body.move_and_collide(correction_vector)
				current_length *= ratio
	
	_update_children()


func _update_children() -> void:
	# moves all children to the kinematic body
	var target := kinematic_body.global_transform.origin
	for child in get_children():
		child.global_transform.origin = target


func _move_kinematic_body(length:=current_length) -> KinematicCollision:
	# moves the kinematic body to the current end of the arm
	return kinematic_body.move_and_collide(- global_transform.basis.z * length + global_transform.origin - kinematic_body.global_transform.origin)


func _reset_kinematic_body() -> void:
	# teleports the kinematic body as close as possible to the origin
	kinematic_body.global_transform.origin = - global_transform.basis.z * min_length + global_transform.origin
