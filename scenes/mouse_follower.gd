extends StaticBody2D

var area2d : Area2D
var draggedRB : Node2D

# Variable to track how fast we are throwing the object
var current_velocity : Vector2 = Vector2.ZERO 

func _on_begin_drag(otherObject : Node2D):
	$RemoteTransform2D.remote_path = otherObject.get_path()
	draggedRB = otherObject
	
	# Stop the object's own momentum while we hold it
	if "velocity" in draggedRB:
		draggedRB.velocity = Vector2.ZERO
	
	if "beingDragged" in draggedRB:
		draggedRB.beingDragged = true
		
	DraggingManager.is_dragging = true

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("drag"):
		check_below_mouse()
		
	if Input.is_action_pressed("drag"):
		var target_pos = get_global_mouse_position()
		
		# 1. Calculate Velocity
		# We compare where we want to be (mouse) vs where we are now
		var raw_velocity = (target_pos - global_position) / delta
		
		# Smooth the velocity (Lerp) to avoid jittery throwing
		current_velocity = current_velocity.lerp(raw_velocity, 15 * delta)
		
		# 2. Move to mouse
		global_position = target_pos 
	
	if Input.is_action_just_released("drag"):
		DraggingManager.is_dragging = false
		_on_release()

func check_below_mouse():
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query, 32)
	
	if results.size() > 0:
		var top_object = null
		var max_z = -99999
	
		for hit in results:
			var collider = hit.collider
			
			if collider is CanvasItem and collider.is_in_group("Grabbable"):
				if collider.z_index > max_z:
					max_z = collider.z_index
					top_object = collider
		
		if top_object:
			_on_begin_drag(top_object)

func _on_release():
	if draggedRB:
		draggedRB.global_transform = $RemoteTransform2D.global_transform
		
		# FIX: Tell the object to immediately re-scan its surroundings
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

func _snap_to_pos():
	if DraggingManager.goalBody:
		# TOdo 
		draggedRB.global_transform = DraggingManager.goalBody.global_transform
	else:
		pass
				# Free placement
