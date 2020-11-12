# Gives 4 state movement functionality to the parent character
# The character will be able to sprint, run, walk or air strafe with this script
# Also provides user input support
class_name CharacterMovement2D
extends Node


enum RotationStyles {FACE_MOUSE, FACE_NODE, FACE_MOVEMENT}
enum MovementStates {DEFAULT, SLOW, FAST}

export var fast_speed := 10.0
export var default_speed := 5.0
export var slow_speed := 2.5
export(MovementStates) var movement_state := MovementStates.DEFAULT	# Corresponds to the speed that the character will move at
export var auto_rotate := true			# If true, the body_node will be flipped to according to rotation_style

# The direction the body_node will face when moving
# FACE_MOUSE will turn towards the mouse
# FACE_NODE will turn towards target_node
# FACE_MOVMENT will turn towards the movement_vector
export(RotationStyles) var rotation_style := RotationStyles.FACE_MOVEMENT
export var counter_rotate_basis := true								# Counter rotates the basis_node so that it is not affected by auto_rotate
export var basis_node_path: NodePath = ".."							# The node which the movement vector will be relative to (modifying after _ready has no effect)
export var body_node_path: NodePath									# The node which will be flipped to follow the movement_vector (modifying after _ready has no effect)
export var target_node_path: NodePath

var movement_vector: Vector2
var target_node: Node2D

# Modify these after _ready if need be, instead of basis_node_path
onready var basis_node: Node2D = get_node(basis_node_path)
onready var body_node: Node2D = get_node(body_node_path)
onready var character: Character2D = get_parent()


func _ready():
	if not target_node_path.is_empty():
		target_node = get_node(target_node_path)


func _process(_delta):
	var tmp_vector = basis_node.to_global(movement_vector) - basis_node.global_transform.origin
	
	match movement_state:
		MovementStates.FAST:
			tmp_vector *= fast_speed
		
		MovementStates.SLOW:
			tmp_vector *= slow_speed
		
		_:
			tmp_vector *= default_speed
	
	character.movement_vector = tmp_vector
	
	if auto_rotate:
		match rotation_style:
			RotationStyles.FACE_MOUSE:
				if body_node.to_local(body_node.get_global_mouse_position()).x < 0:
					body_node.global_transform.x *= -1
			
			RotationStyles.FACE_NODE:
				if body_node.to_local(target_node.global_transform.origin).x < 0:
					body_node.global_transform.x *= -1
			
			RotationStyles.FACE_MOVEMENT:
				if body_node.to_local(tmp_vector + body_node.global_transform.origin).x < 0:
					body_node.global_transform.x *= -1
