# A simple label designed to show the speed of its parent
extends Label


var _last_origin: Vector3

onready var target: Spatial = get_parent()


func _physics_process(delta):
	text = target.name + " speed: " + str(_last_origin.distance_to(target.global_transform.origin) / delta)
	_last_origin = target.global_transform.origin
