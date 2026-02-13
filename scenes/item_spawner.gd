extends Area2D

var item_scenes: Array[PackedScene] = []
var spawn_offset: Vector2 = Vector2(0, -50)

func _ready() -> void:
	_load_item_scenes()
	input_event.connect(_on_input_event)

func _load_item_scenes() -> void:
	var dir = DirAccess.open("res://scenes/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var scene_path = "res://scenes/items/" + file_name
				var scene = load(scene_path) as PackedScene
				if scene:
					item_scenes.append(scene)
			file_name = dir.get_next()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _has_grabbable_at_mouse():
			_spawn_random_item()

func _has_grabbable_at_mouse() -> bool:
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query, 32)
	
	for hit in results:
		var collider = hit.collider
		if collider is CanvasItem and collider.is_in_group("Grabbable"):
			return true
	
	return false

func _spawn_random_item() -> void:
	if item_scenes.is_empty():
		push_warning("No item scenes loaded!")
		return
	
	var random_scene = item_scenes[randi() % item_scenes.size()]
	var item_instance = random_scene.instantiate()
	
	if item_instance:
		var scene_root = get_tree().current_scene
		scene_root.add_child(item_instance)
		item_instance.global_position = global_position + spawn_offset
		item_instance.scale = Vector2(1, 1)
