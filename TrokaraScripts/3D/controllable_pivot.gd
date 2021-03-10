# Provides an easy way for AI to rotate this node towards a local or global position
# Also provides an easy way to turn mouse motion into rotation
class_name ControllablePivot
extends PivotPoint


export var mouse_sensitivity := 0.002
export var invert_x := false
export var invert_y := false
export var mouse_lock := true setget set_mouse_lock		# If true, this node can accept user input for rotating
export var max_speed := 1.0				# used to determine how fast the joypad can rotate this pivot
export var joypad_threshold := 0.05

var joypad_idx: int


func _ready():
	# has to be called again as the setter for the export var is called before ready (which doesnt change process input)
	set_mouse_lock(mouse_lock)
	update_joypad()
	Input.connect("joy_connection_changed", self, "update_joypad")


func update_joypad(_device=0, _connected=true) -> void:
	var connected_joypads := Input.get_connected_joypads()
	
	if not connected_joypads.empty():
		set_process(true)
		joypad_idx = connected_joypads[0]
	
	else:
		set_process(false)


func set_mouse_lock(value: bool) -> void:
	mouse_lock = value
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
	var axis_vectors := Vector2(Input.get_joy_axis(joypad_idx, JOY_ANALOG_RX), Input.get_joy_axis(joypad_idx, JOY_ANALOG_RY))
	
	if abs(axis_vectors.x) < joypad_threshold:
		axis_vectors.x = 0
	
	elif invert_x:
		axis_vectors.x *= -1
	
	if abs(axis_vectors.y) < joypad_threshold:
		axis_vectors.y = 0
	
	elif invert_y:
		axis_vectors.y *= -1
	
	axis_vectors *= max_speed * delta
	biaxial_rotate(axis_vectors.y, axis_vectors.x)
