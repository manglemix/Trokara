class_name CollisionData3D
extends Resource


var character: KinematicBody

var position: Vector3
var normal: Vector3
var travel: Vector3
var remainder: Vector3
var collider: Node
var collider_shape: Object
var collider_velocity: Vector3
var collision_time: int


func _init(kinematic_collision: KinematicCollision, _character: KinematicBody):
	character = _character
	
	position = kinematic_collision.position
	normal = kinematic_collision.normal
	travel = kinematic_collision.travel
	remainder = kinematic_collision.remainder
	collider = kinematic_collision.collider
	collider_shape = kinematic_collision.collider_shape
	collider_velocity = kinematic_collision.collider_velocity
	collision_time = OS.get_system_time_msecs()


func is_floor() -> bool:
	return normal.angle_to(character.up_vector) <= character.floor_max_angle


func is_ceiling() -> bool:
	return normal.is_equal_approx(character.down_vector)


func is_wall() -> bool:
	return (not is_ceiling()) and (not is_floor())
