# Rotates the parent to follow the floor rotation
class_name FollowFloorRotation
extends Node


export var movement_source_path: NodePath = ".."			# The path to the node which has a movement_vector (usually the character; modifying this after _ready has no effect)
export var enabled := true setget set_enabled				# If true, this node's process method will run
export var counter_rotate_target_path: NodePath				# If given, the given node will not be affected by the rotation of the parent
															# This is mostly only used if the parent of this node is the character, and the camera is parented to the character
															# This will allow the camera to not be rotated by this node

var counter_rotate_target: Spatial							# The node whose rotation will not be changed by this node

var _is_ready := false
var first_contact := false
var angle_offset :float = 0

# The node which has a movement_vector (usually the character; modify this variable instead of movement_source_path if needed)
onready var movement_source: Spatial = get_node(movement_source_path)

func set_enabled(value: bool) -> void:
	enabled = value
	if not _is_ready:
		yield(self, "ready")
	
	set_process(value)


func _ready():
	if not counter_rotate_target_path.is_empty():
		counter_rotate_target = get_node(counter_rotate_target_path)
	
	_is_ready = true


func _process(delta):
	if movement_source.floor_collision != null:
		# Forces to get the angle offset only the first time it touches a floor, needed for correct angle when touching the floor without character movement
		if not first_contact:
			first_contact = true
			angle_offset = get_parent().global_transform.basis.get_euler().y - movement_source.floor_collision.collider.global_transform.basis.get_euler().y
		
		# Only sets the angle offset if the character is not moving
		if movement_source.floor_velocity.length() > 0.01 and movement_source.movement_vector.length() <= 0.01:
			var original_basis: Basis
			
			if is_instance_valid(counter_rotate_target):
				original_basis = counter_rotate_target.global_transform.basis
			
			get_parent().global_transform.basis = Basis(Vector3.UP, movement_source.floor_collision.collider.global_transform.basis.get_euler().y + angle_offset)
			
			if is_instance_valid(counter_rotate_target):
				counter_rotate_target.global_transform.basis = original_basis
		else:
			angle_offset = get_parent().global_transform.basis.get_euler().y - movement_source.floor_collision.collider.global_transform.basis.get_euler().y
	else:
		first_contact = false
