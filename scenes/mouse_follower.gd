extends StaticBody2D



var area2d : Area2D
var draggedRB : RigidBody2D

# Called when the node enters the scene tree for the first time.



func _on_begin_drag(otherObject : Node2D):
	$Spring2d.node_a = self.get_path()
	$Spring2d.node_b = otherObject.get_path()
	draggedRB = otherObject as RigidBody2D
	print($Spring2d.node_b)


func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("drag"):
		check_below_mouse()
	if Input.is_action_pressed("drag"):
		global_position = get_global_mouse_position() 
		
	if Input.is_action_just_released("drag"):
		DraggingManager.is_dragging = false
		_on_release()
	
		#Unparent and let keep momentum of object
		#tween.tween_callback(print_done)

func _physics_process(delta: float) -> void:
	if draggedRB != null:
		draggedRB.apply_central_force(draggedRB.linear_velocity * -0.3)
	
func check_below_mouse():
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	
	# 1. Setup a point query
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true # Set to true if your objects are Areas
	query.collide_with_bodies = true
	
	# 2. Get ALL overlapping results (up to 32 objects)
	var results = space_state.intersect_point(query, 32)
	
	if results.size() > 0:
		var top_object = null
		var max_z = -99999 # Start with a very low Z
	
		for hit in results:
			var collider = hit.collider
			
			# Check if this object is higher than our current 'top'
			# Note: We check z_index, but you could also check CanvasItem.z_as_relative
			if collider is CanvasItem:
				if collider.z_index > max_z:
					max_z = collider.z_index
					top_object = collider
		
		if top_object:
			print("Clicked on the top object: ", top_object.name)
			_on_begin_drag(top_object)

func _on_release():
	$Spring2d.node_b = NodePath("")
	draggedRB = null
