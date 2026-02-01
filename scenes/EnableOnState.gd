extends CanvasItem
# This script can now be attached to any 2D or UI node

@export var valid_states : Array[AppStateManager.States]

func _ready() -> void:
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
	# Initialize state immediately
	_on_game_state_changed()

func _on_game_state_changed() -> void:
	var is_valid = valid_states.has(AppStateManager.currentState)
	
	if is_valid:
		process_mode = PROCESS_MODE_INHERIT
		show()
	else:
		process_mode = PROCESS_MODE_DISABLED
		hide()
	for cam in self.find_children("*", "Camera2D"):
		var camera : Camera2D = cam
		camera.enabled = is_valid
