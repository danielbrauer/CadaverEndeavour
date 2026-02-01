extends StaticBody2D

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.GAMEOVER:
		return

	var bodies: Array[Area2D] = $Area2D.get_overlapping_areas()
	
	for body in bodies:
		if body.is_in_group("Grabbable"):
			_stop_animations(body)
			body.reparent(self)
			call_deferred("_stop_animations", body)
			body.collision_layer = 0
			body.collision_mask = 0

func _stop_animations(node: Node) -> void:
	if not node:
		return
	var animation_players = node.find_children("*", "AnimationPlayer", true, false)
	for anim_player in animation_players:
		if anim_player is AnimationPlayer:
			anim_player.stop()
			anim_player.seek(0.0, true)
	if node is AnimationPlayer:
		node.stop()
		node.seek(0.0, true)
