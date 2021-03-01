# Provides an easy way for AI to rotate this node towards a local or global position
# Also provides an easy way to turn mouse motion into rotation
class_name ControllablePivot
extends PivotPoint


export var mouse_sensitivity := 0.002
export var max_speed := 1.0				# used to determine how fast the joypad can rotate this pivot
export var invert_x := false
export var invert_y := false
export var accept_input := true setget set_accept_input		# If true, this node can accept user input for rotating


func _ready():
	# has to be called again as the setter for the export var is called before ready (which doesnt change process input)
	set_accept_input(accept_input)


func set_accept_input(value: bool) -> void:
	accept_input = value
	set_process_input(value)
	
	if value:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event):
	if event is InputEventMouseMotion:
		if invert_x:
			event.relative.x *= -1
		
		if invert_y:
			event.relative.y *= -1
		
		var vector: Vector2 = - event.relative * mouse_sensitivity
		biaxial_rotate(vector.y, vector.x)


func _process(delta: float):
	var connected_joypads := Input.get_connected_joypads()
	
	if not connected_joypads.empty():
		var device: int = connected_joypads[0]
		var axis_vectors := Vector2(Input.get_joy_axis(device, JOY_ANALOG_RX), Input.get_joy_axis(device, JOY_ANALOG_RY)) * max_speed * delta
		
		if invert_x:
			axis_vectors.x *= -1
		
		if invert_y:
			axis_vectors.y *= -1
		
		biaxial_rotate(axis_vectors.y, axis_vectors.x)
