extends Node

signal OnGameStateChanged

enum States {MENU,INTRO,GAME,GAMEOVER, ENDSCREEN, FREEPLAY}

# The 'setget' equivalent in Godot 4 uses the ':' syntax
var currentState : States = States.MENU:
	set(value):
		if currentState != value:
			currentState = value
			OnGameStateChanged.emit()
