extends AnimationTree


const MOVEMENT_TRANSITION_WEIGHT := 9.0

var _character_is_moving: bool
var _state_playback: AnimationNodeStateMachinePlayback = get("parameters/playback")

onready var character: Character = get_parent()
onready var jump_controller: CharacterJump = $"../ControllableCharacterJump"
onready var _last_origin := character.global_transform.origin


func _ready():
	# warning-ignore-all:return_value_discarded
	jump_controller.connect("jumped", self, "handle_jump")
	character.connect("landed", self, "handle_landing")


func handle_jump() -> void:
	if _character_is_moving:
		_state_playback.travel("running_jump")

	else:
		_state_playback.travel("standing_jump")


func handle_landing(vertical_speed: float, _on_floor) -> void:
	if vertical_speed <= - 7.5:
		_state_playback.travel("land")


func _process(delta: float):
	if delta == 0:
		return
	
	_character_is_moving = not is_zero_approx(character.movement_vector.length_squared())
	var new_origin := character.global_transform.origin
	var speed := new_origin.distance_to(_last_origin) / delta
	_last_origin = new_origin
	
	if character.is_on_floor():
		if _character_is_moving:
			_state_playback.travel("walk_run")
			
			if speed >= 7.5:
				set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 1, MOVEMENT_TRANSITION_WEIGHT * delta))
			
			else:
				set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 0, MOVEMENT_TRANSITION_WEIGHT * delta))

		else:
			_state_playback.travel("idle")
	
	elif not jump_controller.jumping:
		_state_playback.travel("falling_idle")
