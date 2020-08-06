# A subclass of KinematicArm which can use the scroll wheel to zoom in and out
class_name ControllableKinematicArm
extends KinematicArm


export var scroll_step := 0.5	# how much the arm moves with each scroll
export var min_length := 1.0	# the closest the arm can get to the origin
export var max_length := 7.5	# the furthest the arm can be from the origin


func _input(event):
	if event is InputEventMouseButton:
		# self is used here to call the setter function
		if event.button_index == BUTTON_WHEEL_UP:
			if target_length >= min_length + scroll_step:
				target_length -= scroll_step
			
			else:
				target_length = min_length
		
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if target_length <= max_length - scroll_step:
				target_length += scroll_step
			
			else:
				target_length = max_length
