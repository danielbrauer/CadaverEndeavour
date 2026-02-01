extends Node

signal OnGameStateChanged

enum States {MENU,INTRO,GAME,GAMEOVER, ENDSCREEN}

# The 'setget' equivalent in Godot 4 uses the ':' syntax
var currentState : States = States.MENU:
	set(value):
		if currentState != value:
			var old_state = currentState
			currentState = value
			print(currentState)
			OnGameStateChanged.emit()
