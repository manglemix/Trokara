# Rotates the parent to follow the orientation of another node
# Has the ability to rotate all the time, or only when the movement_source is moving
class_name CopyBasis
extends Node


export var movement_source_path: NodePath = ".."	# The path to the node which has a movement_vector (usually the character; modifying this after _ready has no effect)
export var enable_pitch_rotation := false			# If true, the parent will be able to turn up and down to face the movement_vector
export var interpolation_weight := 0.1				# If interpolation is not desired, set to 1
export var basis_node_path: NodePath				# The path to the node whose orientation will be followed (usually the camera or a pivot; modifying this after _ready has no effect)
export var enabled := true setget set_enabled		# If true, this node's process method will run
export var always_rotate := false					# If true, the parent will always be rotated to follow the bass_node

var _is_ready := false

onready var movement_source: Spatial = get_node(movement_source_path)	# The node which has a movement_vector (usually the character; modify this variable instead of movement_source_path if needed)
onready var basis_node: Spatial = get_node(basis_node_path)				# The path to the node whose orientation will be followed (usually the character; modify this variable instead of basis_node_path if needed)


func set_enabled(value: bool) -> void:
	enabled = value
	if not _is_ready:
		yield(self, "ready")
	
	set_process(value)


func _ready():
	_is_ready = true


func _process(_delta):
	if always_rotate or not is_zero_approx(movement_source.movement_vector.length_squared()):
		var original_basis := basis_node.global_transform.basis
		var rotation := original_basis.get_euler()
		
		if not enable_pitch_rotation:
			rotation.x = 0
		
		get_parent().global_transform.basis = get_parent().global_transform.basis.slerp(Basis(rotation), interpolation_weight)
		basis_node.global_transform.basis = original_basis
