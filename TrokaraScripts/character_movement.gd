# Gives 4 state movement functionality to the parent character
# The character will be able to sprint, run, walk or air strafe with this script
# Also provides user input support
class_name CharacterMovement
extends Node


enum RotationStyles {COPY_BASIS, FACE_MOVEMENT}
enum {DEFAULT, SLOW, FAST}

export var sprint_speed := 10.0
export var default_speed := 5.0
export var walk_speed := 2.5
export var air_speed := 5.0				# The speed when air strafing
export var auto_rotate := true			# If true, the character will rotate according to the rotation_style when moving
export var auto_rotate_weight := 6.0	# The weight used to interpolate the rotation of the character

# The direction the character will face when moving
# FACE_MOVMENT will turn towards the movement_vector
# COPY_BASIS will turn towards the - z axis of the basis_node
export(RotationStyles) var rotation_style := RotationStyles.FACE_MOVEMENT
export var counter_rotate_basis := true								# Counter rotates the basis_node so that it is not affected by auto_rotate
export var basis_node_path: NodePath = ".."							# The node which the movement vector will be relative to (modifying after _ready has no effect)

var movement_state := DEFAULT		# Corresponds to the speed that the character will move at
var movement_vector: Vector3		# The vector towards which the character will move to, within the local space of the basis_node

onready var basis_node: Spatial = get_node(basis_node_path)		# Modify this after _ready if need be, instead of basis_node_path
onready var character: Character = get_parent()


func _process(delta):
	if is_zero_approx(movement_vector.length_squared()):
		character.movement_vector = Vector3.ZERO
	
	else:
		var tmp_vector := basis_node.global_transform.basis.xform(movement_vector)
		
		if character.is_on_floor():
			match movement_state:
				FAST:
					tmp_vector *= sprint_speed
				
				SLOW:
					tmp_vector *= walk_speed
				
				_:
					tmp_vector *= default_speed
		
		else:
			tmp_vector *= air_speed
		
		character.movement_vector = tmp_vector
		
		if auto_rotate:
			var original_basis: Basis
			if counter_rotate_basis:
				original_basis = basis_node.global_transform.basis
			
			if rotation_style == RotationStyles.COPY_BASIS:
				tmp_vector = - basis_node.global_transform.basis.z
			
			tmp_vector -= tmp_vector.project(character.global_transform.basis.y)	# flatten the tmp_vector
			var target_transform := character.global_transform.looking_at(tmp_vector + character.global_transform.origin, character.global_transform.basis.y)
			character.global_transform = character.global_transform.interpolate_with(target_transform, auto_rotate_weight * delta)
			
			if counter_rotate_basis:
				basis_node.global_transform.basis = original_basis
