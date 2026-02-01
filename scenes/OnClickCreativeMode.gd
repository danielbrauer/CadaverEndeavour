extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	enter_creative_mode()

func enter_creative_mode() -> void:
	# Re-enable decorations for dragging
	_restore_decorations()
	# Switch to creative mode state
	AppStateManager.currentState = AppStateManager.States.CREATIVE

func _restore_decorations() -> void:
	# Find the attachment scene that holds reparented decorations
	var attachment_nodes = get_tree().get_nodes_in_group("Attachment")
	if attachment_nodes.is_empty():
		return

	var attachment_scene = attachment_nodes[0]

	# Find all grabbable children that were reparented during GAMEOVER
	# They are now direct children of the AttachmentScene2
	for child in attachment_scene.get_children():
		if child.is_in_group("Grabbable") and child is Area2D:
			_enable_grabbable(child)

func _enable_grabbable(grabbable: Area2D) -> void:
	grabbable.collision_layer = 1
	grabbable.collision_mask = 1
	grabbable.input_pickable = true
	grabbable.monitoring = true
	grabbable.monitorable = true
	grabbable.set_process(true)

	# Reset dying state if applicable
	if "is_dying" in grabbable:
		grabbable.is_dying = false
	if "is_inside_dropable" in grabbable:
		grabbable.is_inside_dropable = true
