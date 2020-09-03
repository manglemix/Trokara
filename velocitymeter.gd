class_name VelocityMeter
extends Control


export var color := Color.red
export var width := 2.0
export var scale := 1.0

var _last_origin: Vector3
var _velocity: Vector3

onready var target: Spatial = get_parent()


func _process(delta):
	_velocity = (target.global_transform.origin - _last_origin) / delta
	_last_origin = target.global_transform.origin
	update()


func _draw():
	var camera := get_viewport().get_camera()
	var to := _last_origin + _velocity * scale
	
	if not (camera.is_position_behind(_last_origin) or camera.is_position_behind(to)):
		draw_line(camera.unproject_position(_last_origin), camera.unproject_position(to), Color.red, width, true)
