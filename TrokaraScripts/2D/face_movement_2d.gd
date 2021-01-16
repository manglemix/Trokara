# Rotates the parent node to face the movement_vector from the movement_source
class_name FaceMovement2D
extends Node


export var movement_source_path: NodePath = ".."			# The path to the node which has a movement_vector (usually the character; modifying this after _ready has no effect)
export var use_true_movement := false						# If true, the parent will face the direction the movement source is actually moving (useful when you want the character to face along the wall when sliding on it)
export var enable_pitch_rotation := false					# If true, the parent will be able to turn up and down to face the movement_vector
export var enable_flip := true
export var interpolation_weight := 0.1						# If interpolation is not desired, set to 1
export var enabled := true setget set_enabled				# If true, this node's process method will run
export var always_rotate := true							# If true, the character will always rotate to the movement_vector even if there was no movement (it will look at the last movement_vector)
export var counter_rotate_target_path: NodePath				# If given, the given node will not be affected by the rotation of the parent
															# This is mostly only used if the parent of this node is the character, and the camera is parented to the character
															# This will allow the camera to not be rotated by this node

var counter_rotate_target: Node2D							# The node whose rotation will not be changed by this node

var _is_ready := false
var _last_movement_vector: Vector2

# The node which has a movement_vector (usually the character; modify this variable instead of movement_source_path if needed)
onready var movement_source: Node2D = get_node(movement_source_path)
onready var _last_origin := movement_source.global_transform.origin


func set_enabled(value: bool) -> void:
	enabled = value
	if not _is_ready:
		yield(self, "ready")
	
	set_process(value)


func _ready():
	if not counter_rotate_target_path.is_empty():
		counter_rotate_target = get_node(counter_rotate_target_path)
	
	_is_ready = true


func _process(_delta):
	var tmp_vector: Vector2
	
	if use_true_movement:	
		var new_origin := movement_source.global_transform.origin
		tmp_vector = new_origin - _last_origin
		_last_origin = new_origin
	
	else:
		tmp_vector = movement_source.movement_vector
	
	if always_rotate:
		if is_zero_approx(tmp_vector.length()):
			tmp_vector = _last_movement_vector
		
		else:
			# only update last movement vector if the new movement vector is nonzero
			_last_movement_vector = tmp_vector
	
	if not enable_pitch_rotation:
		tmp_vector -= tmp_vector.project(get_parent().global_transform.basis.y)		# Flatten the vector
	
	if not is_zero_approx(tmp_vector.length()):
		var transform: Transform2D = get_parent().global_transform
		
		if enable_flip and transform.basis_xform_inv(tmp_vector).x < 0:
			transform.x *= -1
		
		if enable_pitch_rotation:
			transform.rotated(transform.x.angle_to(tmp_vector))
		
		var original_x: Vector2
		var original_y: Vector2

		if is_instance_valid(counter_rotate_target):
			original_x = counter_rotate_target.global_transform.x
			original_y = counter_rotate_target.global_transform.y

		get_parent().global_transform = get_parent().global_transform.interpolate_with(transform, interpolation_weight)

		if is_instance_valid(counter_rotate_target):
			counter_rotate_target.global_transform.x = original_x
			counter_rotate_target.global_transform.y = original_y
