extends Control

func on_finished() -> void:
	AppStateManager.currentState = AppStateManager.States.INTRO

func _on_start_game_pressed() -> void:
	$AudioStreamPlayer.play()
	
	var shake_duration = 0.05
	var shake_rotation = 0.15
	var shake_amount: = 20.0
	
	var tween = get_tree().create_tween()
	
	for i in shake_amount:
		tween.tween_property($Telephone, "rotation", shake_rotation, shake_duration)
		tween.tween_property($Telephone, "rotation", shake_rotation * -1, shake_duration)
		
		if (i + 1 == shake_amount):
			tween.tween_property($Telephone, "rotation", 0, shake_duration)

	$AudioStreamPlayer.finished.connect(on_finished)
