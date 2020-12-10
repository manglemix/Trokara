# Allows user input to cause the parent character to jump
class_name ControllableCharacterJump
extends CharacterJump


# Allows the player to jump even if not on the ground, if the character lands within this amount of time
export var jump_buffer := 0.1

var _last_release_time: int		# used for jump buffering


func _input(event):
	if event.is_action_pressed("jump"):
		if not _initial_jumped or current_jumps > 0:
			set_jumping(true)
	
		else:
			# This is the jump buffer code
			# If the character is in the air, wait until it lands, then check the difference in time
			var _last_jump_query := OS.get_system_time_msecs()
			yield(character, "landed")
			if (OS.get_system_time_msecs() - _last_jump_query) / 1000.0 <= jump_buffer:
				set_jumping(true)
	
				# Cancel the jump if the spacebar is not pressed
				# which is possible if the spacebar was released before the floor was hit
				# factors in the time the spacebar was held down before it was released
				if not Input.is_action_pressed("jump"):
					yield(get_tree().create_timer((_last_release_time - _last_jump_query) / 1000.0), "timeout")
					set_jumping(false)
	
	elif event.is_action_released("jump"):
		_last_release_time = OS.get_system_time_msecs()
		set_jumping(false)
