extends AnimationTree


export var movement_controller_path: NodePath = "../CharacterMovement"
export var jump_controller_path: NodePath = "../CharacterJump"
export var movement_transition_weight := 9.0
export var landing_speed_cutoff := 7.5

var _character_is_moving: bool
var _state_playback: AnimationNodeStateMachinePlayback = get("parameters/playback")

onready var character: Character = get_parent()
onready var movement_controller: CharacterMovement = get_node(movement_controller_path)
onready var jump_controller: CharacterJump = get_node(jump_controller_path)


func _ready():
	# warning-ignore-all:return_value_discarded
	jump_controller.connect("jumped", self, "handle_jump")
	character.connect("landed", self, "handle_landing")


func handle_jump() -> void:
	if _character_is_moving:
		_state_playback.travel("running_jump")

	else:
		_state_playback.travel("standing_jump")


func handle_landing(vertical_speed: float) -> void:
	if vertical_speed <= - landing_speed_cutoff:
		_state_playback.travel("land")


func _process(delta):
	_character_is_moving = not is_zero_approx(character.movement_vector.length_squared())
	
	if character.is_on_floor():
		if _character_is_moving:
			_state_playback.travel("walk_run")
			
			match movement_controller.movement_state:
				movement_controller.FAST:
					set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 1, movement_transition_weight * delta))
				
				movement_controller.SLOW:
					set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), - 1, movement_transition_weight * delta))
				
				_:
					set("parameters/walk_run/blend_position", lerp(get("parameters/walk_run/blend_position"), 0, movement_transition_weight * delta))

		else:
			_state_playback.travel("idle")
	
	elif not jump_controller.jumping:
		_state_playback.travel("falling_idle")
