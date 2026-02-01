extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func restart():
	AppStateManager.request_state_change(AppStateManager.States.MENU)
	get_tree().reload_current_scene()	

func _on_pressed() -> void:
	restart()
