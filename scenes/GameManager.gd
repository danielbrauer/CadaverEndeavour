# GameSequence.gd
extends Node

@export var animation_delay: float = 2.0

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	AudioManager.OnMainAudioFinished.connect(_on_main_audio_finished)
	
func _on_game_state_changed():
	if AppStateManager.currentState != AppStateManager.States.INTRO:
		return
	_run_game_sequence()

func _run_game_sequence():
	await get_tree().create_timer(animation_delay).timeout
	AppStateManager.currentState = AppStateManager.States.GAME

func _on_main_audio_finished() -> void:
	AppStateManager.currentState = AppStateManager.States.GAMEOVER
