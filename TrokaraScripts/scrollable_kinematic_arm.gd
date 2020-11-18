# A subclass of KinematicArm which can use the scroll wheel to zoom in and out
class_name ScrollableKinematicArm
extends KinematicArm


export var scroll_step := 0.5	# how much the arm moves with each scroll
export var max_length := 10.0


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			target_length = clamp(current_length - scroll_step, min_length, max_length)
		
		elif event.button_index == BUTTON_WHEEL_DOWN:
			target_length = clamp(current_length + scroll_step, min_length, max_length)
