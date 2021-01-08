# A quick node to allow a character to be controlled by user input
# Must be a direct child of the Character
class_name MovementInput
extends Node


export var fast_speed := 10.0
export var default_speed := 5.0
export var slow_speed := 2.5
export var basis_node_path: NodePath			# If given, the user input will be transformed to be relative to the node given

var basis_node: Spatial


func _ready():
	if not basis_node_path.is_empty():
		basis_node = get_node(basis_node_path)


func _input(_event):
	# feel free to rename the inputs
	
	# the following magic with movement_vector allows finer control with joystick/joypad
	var x := Input.get_action_strength("move right") - Input.get_action_strength("move left")
	var z := Input.get_action_strength("move backward") - Input.get_action_strength("move forward")
	var movement_vector := Vector3(x, 0, z).normalized() * max(abs(x), abs(z))
	
	if Input.is_action_pressed("sprint"):
		movement_vector *= fast_speed
	
	elif Input.is_action_pressed("walk"):
		movement_vector *= slow_speed
	
	else:
		movement_vector *= default_speed
	
	if is_instance_valid(basis_node):
		get_parent().movement_vector = basis_node.global_transform.basis.xform(movement_vector)
	
	else:
		get_parent().movement_vector = movement_vector
