class_name MultiJump
extends ControllableCharacterJump


signal _reset

export var extra_jumps := 2

onready var jumps := extra_jumps


func reset_jumps(_vertical_speed) -> void:
	jumps = extra_jumps
	emit_signal("_reset")


func _ready():
	character.connect("landed", self, "reset_jumps")


func _input(event):
	if event.is_action_pressed("jump"):
		if jumps <= 0:
			# This is the jump buffer code
			# If the character is in the air, wait until it lands, then check the difference in time
			var _last_jump_query := OS.get_system_time_msecs()
			yield(self, "_reset")
			if (OS.get_system_time_msecs() - _last_jump_query) / 1000.0 <= jump_buffer:
				set_jumping(true)
				yield(self, "jumped")
		
				# Immediately cancel the jump if the spacebar is not pressed
				# which is possible if the spacebar was released before the floor was hit
				if not Input.is_action_pressed("jump"):
					set_jumping(false)
		
		elif not jumping:
			set_jumping(true)
			
			if character.air_time > coyote_time:
				jumps -= 1

	elif event.is_action_released("jump"):
		set_jumping(false)
