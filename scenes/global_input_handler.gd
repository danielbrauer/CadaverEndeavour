extends Node

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if Input.is_action_just_pressed("return_to_menu"):
		_return_to_menu()

func _return_to_menu() -> void:
	_cleanup_all_items()
	AppStateManager.currentState = AppStateManager.States.MENU

func _cleanup_all_items() -> void:
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	_remove_grabbable_items_recursive(scene_root)

func _remove_grabbable_items_recursive(node: Node) -> void:
	if node is CanvasItem and node.is_in_group("Grabbable"):
		node.queue_free()
		return
	
	for child in node.get_children():
		_remove_grabbable_items_recursive(child)
