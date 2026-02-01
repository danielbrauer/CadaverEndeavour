# GameSequence.gd
extends Node

@export var animation_delay: float = 2.0
@export var game_duration: float = 90.0 # 1:30 minutes in seconds


func _ready():
	# Start the sequence as soon as the scene loads
	_run_game_sequence()

func _run_game_sequence():
	# 1. On enter scene: Small delay for animation
	await get_tree().create_timer(animation_delay).timeout
	
	# 2. Start the Game (1:30 min timer begins)
	# We access the Autoload directly by its name 'AppStateManager'
	AppStateManager.currentState = AppStateManager.States.GAME
	
	# Wait for 1 minute 30 seconds
	await get_tree().create_timer(game_duration).timeout
	
	# 3. Time over: Set to GAMEOVER
	AppStateManager.currentState = AppStateManager.States.GAMEOVER
