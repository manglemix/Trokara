extends RayCast


export var upward_step := 0.6
export var forward_step := 1.0
export var weight := 15.0
export var nudge_speed := 0.5
export var min_depression_degrees := 80.0 setget set_min_depression_degrees

var min_depression := deg2rad(80) setget set_min_depression

var _lerping := false
var _target_height: float
var _collider: Node

onready var character: Character = get_parent()


func set_min_depression_degrees(angle: float) -> void:
	min_depression_degrees = angle
	min_depression = deg2rad(angle)


func set_min_depression(angle: float) -> void:
	min_depression = angle
	min_depression_degrees = rad2deg(angle)


func _physics_process(delta):
	if _lerping:
		force_raycast_update()
		var cast_distance := get_collision_point().distance_to(global_transform.origin)
		
		if cast_distance >= cast_to.y:
			_lerping = false
			character.remove_collision_exception_with(_collider)
			character.linear_velocity = character.movement_vector
			character.set_physics_process(true)
		
		else:
			character.move_and_slide(character.align_to_floor(character.movement_vector) + character.up_vector * clamp((cast_to.y - cast_distance) * weight, nudge_speed, INF))
		
	elif character.is_on_wall():
		var collision_info := character.get_slide_collision(0)
		if collision_info.normal.angle_to(character.up_vector) >= min_depression:
			_raycast_check(collision_info)


func _raycast_check(collision_info: KinematicCollision, max_iterations:=3, _iteration:=0) -> void:
	global_transform.origin = collision_info.position
	transform.origin.y = cast_to.y
	force_raycast_update()
	
	if is_colliding():
		_target_height = cast_to.y - get_collision_point().distance_to(global_transform.origin)
		
		if _target_height <= upward_step:
			var origin := character.global_transform.origin
			character.global_transform.origin += character.up_vector * _target_height
			character.move_and_slide(character.movement_vector.normalized() * forward_step, character.up_vector, true, 4, character.floor_max_angle)
			_target_height = (character.global_transform.origin - origin).dot(character.up_vector)
			character.global_transform.origin = origin
			
			if character.is_on_wall():
				if _iteration < max_iterations:
					_raycast_check(character.get_slide_collision(0), max_iterations, _iteration + 1)
			
			else:
				_lerping = true
				_collider = collision_info.collider
				character.set_physics_process(false)
				character.add_collision_exception_with(_collider)
				_target_height += character.global_transform.origin.dot(character.up_vector) + character.get("collision/safe_margin")
