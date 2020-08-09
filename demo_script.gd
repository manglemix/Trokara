# Press 1 to switch to FPS, press 2 to switch to TPS
extends Spatial


const FPS := preload("res://fps_demo.tscn")
const TPS := preload("res://tps_demo.tscn")


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	elif event.is_action_pressed("fps") and has_node("TPSDemo"):
		var fps: Spatial = FPS.instance()
		add_child(fps)
		fps.global_transform = $TPSDemo.global_transform
		$TPSDemo.queue_free()
	
	elif event.is_action_pressed("tps") and has_node("FPSDemo"):
		var tps: Spatial = TPS.instance()
		add_child(tps)
		tps.global_transform = $FPSDemo.global_transform
		$FPSDemo.queue_free()
	
	elif event.is_action_pressed("ui_focus_next"):
		var img := get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("screenshot.png")
