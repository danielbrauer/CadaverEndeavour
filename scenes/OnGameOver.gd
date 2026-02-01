extends Node

@export var end_screen_delay: float = 3.0
@export var deadguy: Node2D
@export var outOfScreenPosY: float
func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.GAMEOVER:
		return
	# Ensure the nodes exist before trying to tween them
	if not deadguy or not outOfScreenPosY:
		push_warning("Deadguy or OutOfScreen position not set!")
		AppStateManager.currentState = AppStateManager.States.ENDSCREEN
		return

	var tween: Tween = create_tween()
	
	# 1. Move the deadguy to the target Y position
	# We use transition_expo and ease_in for a "falling" or "sliding" feel
	tween.tween_property(deadguy, "global_position:y", outOfScreenPosY, 1.0)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)
	
	# 2. Wait for the specified delay after the movement (or during)
	tween.tween_interval(end_screen_delay)
	
	# 3. Set to ENDSCREEN state once the tween finishes
	tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	AppStateManager.currentState = AppStateManager.States.ENDSCREEN
