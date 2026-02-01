extends Node2D

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.ENDSCREEN:
		return
	# Start the sequence as soon as the scene loads
	var dead_guys = get_tree().get_nodes_in_group("DeadGuy")
	if !dead_guys:
		return
	
	if dead_guys.is_empty():
		push_warning("No nodes found in group 'DeadGuy'")
		return
		
	var deadguy = dead_guys[0]
	deadguy.reparent(self)
	deadguy.position = Vector2.ZERO
