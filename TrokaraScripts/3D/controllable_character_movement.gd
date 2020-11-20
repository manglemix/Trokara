# A version of CharacterMovement which can accept user input
class_name ControllableCharacterMovement
extends CharacterMovement


func _input(event):
	if event.is_action_pressed("sprint"):
		movement_state = FAST
	
	elif event.is_action_pressed("walk"):
		movement_state = SLOW
	
	elif event.is_action_released("sprint") and movement_state == FAST:
		movement_state = DEFAULT
	
	elif event.is_action_released("walk") and movement_state == SLOW:
		movement_state = DEFAULT
	
	else:
		movement_vector = Vector3(
				Input.get_action_strength("move right") - Input.get_action_strength("move left"),
				0,
				Input.get_action_strength("move backward") - Input.get_action_strength("move forward")
			).normalized()
