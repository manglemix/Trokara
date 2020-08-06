extends Control


var persistent_draw_queue: Array

var _tmp_draw_queue: Array


func queue_temporary_dot(position, radius := 5.0, color := Color.white) -> void:
	assert(position is Vector2 or position is Vector3)
	_tmp_draw_queue.append([position, radius, color])


func _draw():
	var camera := get_viewport().get_camera()
	for dot in _tmp_draw_queue:
		if dot[0] is Vector2:
			draw_circle(dot[0], dot[1], dot[2])
		
		elif not camera.is_position_behind(dot[0]):
			draw_circle(camera.unproject_position(dot[0]), dot[1], dot[2])
	
	_tmp_draw_queue.clear()


func _process(_delta):
	update()
