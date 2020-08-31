# An alternative to SpringArm which uses a KinematicBody that can slide along walls
# This node will project a KinematicBody along the - z vector, and set this nodes children to follow it
# The KinematicBody will be able to move around obstacles which occlude the origin, but not the destination
# This is in contrast to the SpringArm, which will retract even if there is nothing blocking the destination
# This achieves a more natural movement more suitable for cameras in Third Person shooters
class_name KinematicArm
extends Spatial


# The distance from the origin which the KinematicBody will try to reach
export var target_length := 5.0

# When the KinematicBody gets stuck, it will be allowed to stretch further from the origin up to this length
# Once surpassed, the KinematicBody will be teleported back to the origin and re-cast
export var stretch_length := 1.0

# There is built-in interpolation to smoothen harsh movements
export var weight := 12.0

# The shape used by the KinematicBody
export var shape: Shape

# The collision mask of the KinematicBody
export(int, LAYERS_3D_PHYSICS) var collision_mask := 1

# The nodes which the KinematicBody won't collide with
# Do not append to this array after _ready as it won't do anything
# Instead, use kinematic_body.add_collision_exception_with(body)
export(Array, NodePath) var _exclude_paths: Array

var kinematic_body := KinematicBody.new()


func _enter_tree():
	if is_instance_valid(kinematic_body.get_parent()):
		kinematic_body.get_parent().remove_child(kinematic_body)
	
	get_tree().current_scene.call_deferred("add_child", kinematic_body)


func _exit_tree():
	kinematic_body.get_parent().call_deferred("remove_child", kinematic_body)


func _ready():
	kinematic_body.collision_layer = 0
	kinematic_body.collision_mask = collision_mask
	kinematic_body.name = name + "Assistant"
	
	for path in _exclude_paths:
		kinematic_body.add_collision_exception_with(get_node(path))
	
	var collision_shape := CollisionShape.new()
	collision_shape.shape = shape
	kinematic_body.add_child(collision_shape)
	
	set_physics_process(false)
	yield(kinematic_body, "ready")
	set_physics_process(true)


func move_kinematic(vector: Vector3) -> void:
	# warning-ignore:return_value_discarded
	kinematic_body.move_and_slide(vector, Vector3.ZERO, false, 4)


func _physics_process(delta):
	var destination := global_transform.basis.z * - target_length + global_transform.origin
	var travel_vector := destination - kinematic_body.global_transform.origin
	move_kinematic(travel_vector / delta)
	
	var new_origin := kinematic_body.global_transform.origin
	# Checks if the KinematicBody is stretching too far
	if new_origin.distance_to(global_transform.origin) > target_length + stretch_length:
		kinematic_body.global_transform.origin = global_transform.origin
		move_kinematic(destination / delta)
		new_origin = kinematic_body.global_transform.origin
	
	for child in get_children():
		# the vector from the child to the kinematic_body
		var child_displacement_difference: Vector3 = new_origin - child.global_transform.origin
		var distance_difference := child_displacement_difference.length()
		
		# Do not interpolate the child's position if it is sliding along the wall pointing away from the origin, or if the kinematic body is closer to the origin than the child
		if kinematic_body.is_on_wall() and (distance_difference < 0 or (distance_difference > 0 and kinematic_body.get_slide_collision(0).normal.dot(child_displacement_difference.normalized()) > 0)):
			child.global_transform.origin = new_origin
		
		else:
			child.global_transform.origin = child.global_transform.origin.linear_interpolate(new_origin, weight * delta)
