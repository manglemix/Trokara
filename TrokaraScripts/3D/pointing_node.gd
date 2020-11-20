# A simple Spatial Node which can look at another Spatial Node
class_name PointingNode
extends Spatial


export var target_node_path: NodePath setget set_target_node_path
export var extra_rotation: Vector3											# extra rotation in degrees to be applied after look_at is called
export var basis_node_path: NodePath = ".." setget set_basis_node_path		# the node from which the y-vector will be used as the up_vector

var _is_ready := false

onready var target_node: Spatial = get_node(target_node_path) setget set_target_node
onready var basis_node: Spatial = get_node(basis_node_path) setget set_basis_node


func set_target_node_path(path: NodePath) -> void:
	target_node_path = path
	
	if _is_ready:
		target_node = get_node(path)


func set_target_node(node: Spatial) -> void:
	target_node = node
	target_node_path = get_path_to(node)


func set_basis_node_path(path: NodePath) -> void:
	basis_node_path = path
	
	if _is_ready:
		basis_node = get_node(path)


func set_basis_node(node: Spatial) -> void:
	basis_node = node
	basis_node_path = get_path_to(node)


func _ready():
	_is_ready = true


func _physics_process(_delta):
	look_at(target_node.global_transform.origin, basis_node.global_transform.basis.y)
	rotation_degrees += extra_rotation
