extends StaticBody2D

var area2d : Area2D
var draggedRB : Node2D

# Visual Settings
var original_z : int = 0
var original_scale : Vector2 = Vector2.ONE
var lift_scale_factor : float = 1.1
var rotation_speed : float = 0.15

# Physics
var current_velocity : Vector2 = Vector2.ZERO

func _on_begin_drag(otherObject : Node2D):
	var local_offset = otherObject.global_position - self.global_position
	#self.global_transform = otherObject.global_transform
	
	# Local Offset to avoid snapping the dragged object to the root.
	$RemoteTransform2D.position = local_offset
	$RemoteTransform2D.rotation = otherObject.rotation
	$RemoteTransform2D.remote_path = otherObject.get_path()
	draggedRB = otherObject

	
	_stop_animations(draggedRB)
	
	self.original_z = draggedRB.z_index
	self.original_scale = draggedRB.scale
	
	self.draggedRB.z_index = 100
	draggedRB.scale *= self.lift_scale_factor
	
	if "velocity" in draggedRB:
		draggedRB.velocity = Vector2.ZERO
	
	if "beingDragged" in draggedRB:
		draggedRB.beingDragged = true
	   
	DraggingManager.is_dragging = true

func _input(event: InputEvent) -> void:
	# Rotate the CONTROLLER (self), not the object directly.
	# The RemoteTransform2D passes this rotation to the object.
	if draggedRB and DraggingManager.is_dragging:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$RemoteTransform2D.rotation += rotation_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$RemoteTransform2D.rotation -= rotation_speed

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("drag"):
		check_below_mouse()
	   
	if Input.is_action_pressed("drag") and draggedRB:
		var target_pos = get_global_mouse_position()
	   
	   # Calculate Throw Velocity
		var raw_velocity = (target_pos - global_position) / delta
		current_velocity = current_velocity.lerp(raw_velocity, 15 * delta)
	   
	   # Move Controller (Rotation is handled by _input)
		global_position = target_pos
	
	if Input.is_action_just_released("drag"):
		if draggedRB:
			_on_release()

func check_below_mouse():
	self.global_position = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = self.global_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query, 32)
	
	if results.size() > 0:
		var top_object = null
		var max_z = -99999
		var max_index = -1
	
		for hit in results:
			var collider = hit.collider
			if collider is CanvasItem and collider.is_in_group("Grabbable"):
				if collider.z_index > max_z:
					max_z = collider.z_index
					max_index = collider.get_index()
					top_object = collider
				elif collider.z_index == max_z and collider.get_index() > max_index:
					max_index = collider.get_index()
					top_object = collider
					
		if top_object:
			_on_begin_drag(top_object)

func _on_release():
	if not draggedRB: return

	_stop_animations(draggedRB)

	# --- RESET VISUALS ---
	draggedRB.scale = original_scale
	draggedRB.z_index = original_z
	
	# --- REORDER SIBLINGS ---
	# Move to bottom of parent's list to draw on top of siblings
	var parent = draggedRB.get_parent()
	if parent:
		parent.move_child(draggedRB, -1)

	# Apply final position
	draggedRB.global_position = $RemoteTransform2D.global_position
	
	if draggedRB.has_method("force_update_containment"):
		draggedRB.force_update_containment()

	if "velocity" in draggedRB:
		draggedRB.velocity = current_velocity

	if "beingDragged" in draggedRB:
		draggedRB.beingDragged = false

	# Disconnect
	$RemoteTransform2D.remote_path = NodePath("")
	draggedRB = null
	DraggingManager.is_dragging = false
	current_velocity = Vector2.ZERO

func _stop_animations(node: Node) -> void:
	var animation_players = node.find_children("*", "AnimationPlayer", true, false)
	for anim_player in animation_players:
		if anim_player is AnimationPlayer:
			anim_player.stop()
			anim_player.seek(0.0, true)
