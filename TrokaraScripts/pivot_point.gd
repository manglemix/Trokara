# Enforces rotation limits, and can apply excess rotation onto the fallback_node
# This is useful for character heads, as we usually don't want the head to rotate past some limit
# However, if the head did rotate too far, it should rotate the body to follow too
# Also, if sticky_parent is true, the fallback node will always try to rotate back to its original orientation while following the "head"
# This is useful for forming chains such as Head -> Spine -> Player
# As we humans naturally try to keep our spines aligned with our bodies, whilst also turning to help the head turn farther
tool
class_name PivotPoint
extends Spatial


export var _fallback_node_path: NodePath = '..'		# the path to the fallback_node
export var max_pitch := 70.0
export var min_pitch := - 70.0
export var max_yaw := 180.0
export var min_yaw := - 180.0
export var limit_pitch := true		# if true, excess rotation in the x axis will not be applied to the fallback_node
export var limit_yaw := false		# if true, excess rotation in the y axis will not be applied to the fallback_node
export var sticky_parent := false	# if true, the fallback_node will always try to turn back to its original orientation

var fallback_node: Spatial setget set_fallback_node 		# the node which excess rotation from this node will be dumped onto
var _fallback_is_pivot: bool								# True if the fallback_node is a PivotPoint

onready var _initial_transform := transform


func set_fallback_node(node: Spatial) -> void:
	fallback_node = node
	
	# We check if the fallback node is a PivotPoint like this as we can't compare directly (cyclic dependency)
	_fallback_is_pivot = node.has_method("get_relative_transform") and node.has_method("biaxial_rotate")


func _ready():
	set_fallback_node(get_node(_fallback_node_path))


func biaxial_rotate(x: float, y: float) -> void:
	# rotates this node in the x and y axes
	global_rotate(fallback_node.global_transform.basis.y.normalized(), y)
	rotate_object_local(Vector3.RIGHT, x)


func biaxial_rotate_vector(xy: Vector2) -> void:
	# Biaxial rotation using a Vector2
	biaxial_rotate(xy.x, xy.y)


func get_relative_transform() -> Transform:
	# finds the transform relative to the _initial_transform
	return transform * _initial_transform.affine_inverse()


func _physics_process(_delta):
	# because there isn't any way for this node to know if it has been rotated, we have to do all angle checks every frame
	
	if sticky_parent:
		var euler_rotation: Vector3
		if _fallback_is_pivot:
			var parent_transform = fallback_node.get_relative_transform()
			euler_rotation = parent_transform.basis.get_euler()
			
			fallback_node.biaxial_rotate(- euler_rotation)
		
		else:
			var parent_transform = fallback_node.transform
			euler_rotation = parent_transform.basis.get_euler()
		
			fallback_node.global_rotate(fallback_node.global_transform.basis.y.normalized(), - euler_rotation.y)
			fallback_node.rotate_object_local(Vector3.RIGHT, - euler_rotation.x)
		
		# counter rotates this node such that it is still pointing in the same direction globally
		biaxial_rotate(euler_rotation.x, euler_rotation.y)
	
	var euler_rotation := get_relative_transform().basis.get_euler()
	euler_rotation = Vector3(rad2deg(euler_rotation.x),
							rad2deg(euler_rotation.y),
							rad2deg(euler_rotation.z)
							)
	
	# the following code checks if this node has turned past its limits, and will rotate the fallback_node by the difference
	# it will also counter rotate this node to remain underneath the limits
	
	if euler_rotation.y > max_yaw:
		if not limit_yaw:
			fallback_node.rotate_object_local(Vector3.UP, deg2rad(euler_rotation.y - max_yaw))
		
		# counter rotation
		global_rotate(fallback_node.global_transform.basis.y.normalized(), deg2rad(max_yaw - euler_rotation.y))
		
	elif euler_rotation.y < min_yaw:
		if not limit_yaw:
			fallback_node.rotate_object_local(Vector3.UP, deg2rad(euler_rotation.y - min_yaw))
		
		global_rotate(fallback_node.global_transform.basis.y.normalized(), deg2rad(min_yaw - euler_rotation.y))

	if euler_rotation.x > max_pitch:
		if not limit_pitch:
			fallback_node.global_rotate(global_transform.basis.x.normalized(), deg2rad(euler_rotation.x - max_pitch))
		
		rotate_object_local(Vector3.RIGHT, deg2rad(max_pitch - euler_rotation.x))
		
	elif euler_rotation.x < min_pitch:
		if not limit_pitch:
			fallback_node.global_rotate(global_transform.basis.x.normalized(), deg2rad(euler_rotation.x - min_pitch))
		
		rotate_object_local(Vector3.RIGHT, deg2rad(min_pitch - euler_rotation.x))
