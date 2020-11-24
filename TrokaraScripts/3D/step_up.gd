class_name StepUp
extends Spatial


export var shape: Shape setget set_shape
export var character_height := 1.0 setget set_character_height
export var min_depression_degrees := 80.0 setget set_min_depression_degrees
export var step_height := 0.5
export var weight := 30.0

var min_depression := deg2rad(80) setget set_min_depression

var _raycast := RayCast.new()
var _physics_query := PhysicsShapeQueryParameters.new()
var _stepping := false

var character: Character
onready var _direct_space_state := get_world().direct_space_state


func set_shape(value: Shape) -> void:
	shape = value
	_physics_query.set_shape(value)


func set_character_height(height: float) -> void:
	character_height = height
	_raycast.cast_to = Vector3(0, - height, 0)


func set_min_depression_degrees(value: float) -> void:
	min_depression_degrees = value
	min_depression = deg2rad(value)


func set_min_depression(value: float) -> void:
	min_depression = value
	min_depression_degrees = rad2deg(value)


func _ready():
	add_child(_raycast)
	
	if shape == null:
		transform = Transform.IDENTITY
		var collision_shape: CollisionShape = get_parent()
		set_shape(collision_shape.shape)
		character = collision_shape.get_parent()
	
	else:
		character = get_parent()
	
	_raycast.add_exception(character)


func _physics_process(delta):
	if _stepping:
		_physics_query.transform = global_transform
		var rest_info := _direct_space_state.get_rest_info(_physics_query)
		
		if rest_info.empty():
			_stepping = false
		
		else:
			_move_raycast_above_point(rest_info["point"], character.global_transform.basis.y)
	
	elif character.is_on_wall():
		var collision_info := character.get_slide_collision(0)
		_recursive_check(collision_info.position, collision_info.normal, character.global_transform.basis.y, delta)


func _move_raycast_above_point(point: Vector3, up_vector: Vector3) -> void:
	_raycast.global_transform.origin = point - (point - character.global_transform.origin).project(up_vector) + up_vector * character_height


func _recursive_check(collision_point: Vector3, collision_normal: Vector3, up_vector: Vector3, delta: float, max_iterations:=3, iteration:=0) -> void:
	_move_raycast_above_point(collision_point, up_vector)
	_raycast.force_raycast_update()
	
	if _raycast.is_colliding():
		var cast_height := character_height - _raycast.get_collision_point().distance_to(_raycast.global_transform.origin)
		
		if cast_height <= step_height:
			var normal := _raycast.get_collision_normal()
			if normal.angle_to(character.up_vector) <= character.floor_max_angle:
				_physics_query.transform = global_transform
				_physics_query.transform.origin += character.global_transform.basis.y * (cast_height + character.get("collision/step_height")) + character.movement_vector * delta
				var rest_info := _direct_space_state.get_rest_info(_physics_query)
				
				if not rest_info.empty():
					normal = rest_info["normal"]
					if normal.angle_to(character.up_vector) <= character.floor_max_angle:
						_stepping = true
						character.add_collision_exception_with(rest_info["collider"])
					
					elif iteration + 1 < max_iterations:
						_recursive_check(rest_info["point"], normal, up_vector, delta, max_iterations, iteration + 1)
