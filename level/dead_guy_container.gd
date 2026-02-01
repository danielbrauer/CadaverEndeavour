extends Node2D

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.ENDSCREEN:
		return
	# Start the sequence as soon as the scene loads
	var deadguy = get_tree().get_nodes_in_group("DeadGuy")
	if !deadguy:
		return
	deadguy[0].reparent(self)
