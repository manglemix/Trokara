# An analogue to RemoteTransform, which copies the transform of a target node
# If no node is given, one will be made automatically in the current scene, called <this_node's_name>Assistant
class_name TransformReceiver
extends Spatial


export var copy_basis := true					# If true, copies the orientation
export var use_global_basis := true				# If true, the above will use the global orientation
export var copy_origin := false					# If true, copies the position
export var use_global_origin := true			# If true, the above will use the global position
export var target_node_path: NodePath			# The path to the node that this node will target
export var active := true setget set_active

var target_node: Spatial


func set_active(value: bool) -> void:
	active = value
	set_process(value)


func _enter_tree():
	if is_instance_valid(target_node):
		if is_instance_valid(target_node.get_parent()):
			target_node.get_parent().call_deferred("remove_child", target_node)
		
		get_tree().current_scene.call_deferred("add_child", target_node)


func _exit_tree():
	if is_instance_valid(target_node):
		target_node.get_parent().call_deferred("remove_child", target_node)


func _ready():
	if target_node_path.is_empty():
		target_node = Spatial.new()
		target_node.name = name + "Assistant"
	
	else:
		target_node = get_node(target_node_path)
	
	_enter_tree()
	
	# this line is needed to process after the target_node is done processing
	process_priority = 1
	
	# setter has to be called again as it doesn't work before _ready
	set_active(active)


func _process(_delta):
	if copy_basis:
		if use_global_basis:
			global_transform.basis = target_node.global_transform.basis

		else:
			transform.basis = target_node.transform.basis

	if copy_origin:
		if use_global_origin:
			global_transform.origin = target_node.global_transform.origin

		else:
			transform.origin = target_node.transform.origin
