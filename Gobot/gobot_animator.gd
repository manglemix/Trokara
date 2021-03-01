extends AnimationTree


const MOVEMENT_TRANSITION_WEIGHT := 9.0
const THRESHOLD := 0.1

var _is_moving: bool
var _state_playback: AnimationNodeStateMachinePlayback = get("parameters/playback")


func handle_jump() -> void:
	if _is_moving:
		_state_playback.travel("running_jump")

	else:
		_state_playback.travel("standing_jump")


func handle_landing(vertical_speed: float) -> void:
	if vertical_speed <= - 7.5:
		_state_playback.travel("land")


func process_animation(delta: float, linear_velocity: Vector3, is_on_floor: bool, is_jumping: bool):
	if delta == 0:
		return
	
	var speed := linear_velocity.length()
	
	if is_on_floor:
		if speed <= THRESHOLD:
			_is_moving = false
			_state_playback.travel("idle")
		
		else:
			_is_moving = true
			_state_playback.travel("walk_run")
			
			if speed >= 7.5:
				set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 1, MOVEMENT_TRANSITION_WEIGHT * delta))
			
			else:
				set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 0, MOVEMENT_TRANSITION_WEIGHT * delta))
	
	elif not is_jumping:
		_state_playback.travel("falling_idle")
