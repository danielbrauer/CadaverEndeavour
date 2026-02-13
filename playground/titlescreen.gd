extends Control

func _ready() -> void:
	var exit_button = get_node_or_null("ExitButton")
	if exit_button:
		if OS.has_feature("web"):
			exit_button.visible = false
		else:
			exit_button.visible = true

func to_game() -> void:
	AppStateManager.currentState = AppStateManager.States.INTRO

func _on_button_pressed() -> void:
	do_transition(to_game)
	
func do_transition(cb) -> void:
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

	$AudioStreamPlayer.finished.connect(cb)

func _on_exit_button_pressed() -> void:
	if not OS.has_feature("web"):
		get_tree().quit()

func to_free_play() -> void:
	AppStateManager.currentState = AppStateManager.States.FREEPLAY

func _on_free_play_pressed() -> void:
	do_transition(to_free_play)
