# Rotates the parent to follow the orientation of another node
# Has the ability to rotate all the time, or only when the movement_source is moving
class_name CopyBasis
extends Node


export var movement_source_path: NodePath = ".."	# The path to the node which has a movement_vector (usually the character; modifying this after _ready has no effect)
export var enable_pitch_rotation := false			# If true, the parent will be able to turn up and down to face the movement_vector
export var interpolation_weight := 0.1				# If interpolation is not desired, set to 1
export var basis_node_path: NodePath				# The path to the node whose orientation will be followed (usually the camera or a pivot; modifying this after _ready has no effect)

var _original_basis: Basis

onready var basis_node: Spatial = get_node(basis_node_path)				# The path to the node whose orientation will be followed (usually the character; modify this variable instead of basis_node_path if needed)


func get_new_basis(current_basis: Basis) -> Basis:
	_original_basis = basis_node.global_transform.basis
	var rotation := _original_basis.get_euler()
	
	if not enable_pitch_rotation:
		rotation.x = 0
	
	return current_basis.slerp(Basis(rotation), interpolation_weight)


func reset_basis_node() -> void:
	basis_node.global_transform.basis = _original_basis
