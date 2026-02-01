extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func restart():
	print(get_tree().current_scene)
	AppStateManager.currentState = AppStateManager.States.MENU
	get_tree().reload_current_scene()	

func _on_pressed() -> void:
	restart()
