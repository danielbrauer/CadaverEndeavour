extends StaticBody2D

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.GAMEOVER:
		return

	
	var bodies: Array[Area2D] = $Area2D.get_overlapping_areas()
	
	for body in bodies:
		if body.is_in_group("Grabbable"):
			body.reparent(self)
			body.collision_layer = 0
			body.collision_mask = 0
			#TODO: Here get points
