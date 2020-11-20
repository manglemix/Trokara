# A version of CharacterMovement which can accept user input
class_name ControllableCharacterMovement2D
extends CharacterMovement2D


func _input(event):
	if event.is_action_pressed("sprint"):
		movement_state = MovementStates.FAST
	
	elif event.is_action_pressed("walk"):
		movement_state = MovementStates.SLOW
	
	elif event.is_action_released("sprint") and movement_state == MovementStates.FAST:
		movement_state = MovementStates.DEFAULT
	
	elif event.is_action_released("walk") and movement_state == MovementStates.SLOW:
		movement_state = MovementStates.DEFAULT
	
	else:
		movement_vector = Vector2(
				Input.get_action_strength("move right") - Input.get_action_strength("move left"),
				0
			).normalized()
