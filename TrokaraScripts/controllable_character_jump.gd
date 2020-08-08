# Allows user input to cause the parent character to jump
class_name ControllableCharacterJump
extends CharacterJump


# Allows the player to jump even if not on the ground, if the character lands within this amount of time
export var jump_buffer := 0.1


func _input(event):
	if event.is_action_pressed("jump"):
		if character.air_time < coyote_time:
			set_jumping(true)
	
		else:
			# This is the jump buffer code
			# If the character is in the air, wait until it lands, then check the difference in time
			var _last_jump_query := OS.get_system_time_msecs()
			yield(character, "landed")
			if (OS.get_system_time_msecs() - _last_jump_query) / 1000.0 <= jump_buffer:
				set_jumping(true)
				yield(self, "jumped")

				# Immediately cancel the jump if the spacebar is not pressed
				# which is possible if the spacebar was released before the floor was hit
				if not Input.is_action_pressed("jump"):
					set_jumping(false)

	elif event.is_action_released("jump"):
		set_jumping(false)
