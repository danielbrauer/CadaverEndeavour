@tool
class_name ItemSceneGenerator
extends EditorScript

func _run() -> void:
	print("Starting item scene generation...")
	
	var mapping_file = FileAccess.open("res://resources/texture_item_mapping.json", FileAccess.READ)
	if mapping_file == null:
		printerr("Error: Could not open texture_item_mapping.json")
		return
	
	var json_string = mapping_file.get_as_text()
	mapping_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		printerr("Error: Failed to parse texture_item_mapping.json: ", json.get_error_message())
		return
	
	var mapping = json.get_data()
	
	var csv_data = CSVReader.read_csv_to_dict("res://resources/items.data")
	if csv_data.is_empty():
		printerr("Error: Could not load items.data")
		return
	
	var dir = DirAccess.open("res://images/objects/")
	if dir == null:
		printerr("Error: Could not open images/objects/ directory")
		return
	
	var processed_count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".PNG"):
				var item_name = ""
				if mapping.has(file_name):
					item_name = mapping[file_name]
				
				if item_name == "":
					item_name = _filename_to_item_name(file_name)
				
				if csv_data.has(item_name):
					_generate_scene_for_texture(file_name, item_name, csv_data)
					processed_count += 1
				else:
					_generate_scene_for_texture(file_name, item_name, {})
					processed_count += 1
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Generated ", processed_count, " item scenes")

func _generate_scene_for_texture(texture_filename: String, item_name: String, csv_data: Dictionary) -> void:
	var texture_path = "res://images/objects/" + texture_filename
	var texture = load(texture_path) as Texture2D
	
	if texture == null:
		printerr("Error: Could not load texture: ", texture_path)
		return
	
	var image = texture.get_image()
	if image == null:
		printerr("Error: Could not get image from texture: ", texture_path)
		return
	
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	var rect = Rect2i(0, 0, image.get_width(), image.get_height())
	var polygons = bitmap.opaque_to_polygons(rect)
	
	if polygons.is_empty():
		print("Warning: No polygons generated for ", texture_filename, " - using bounding box")
		var bounding_polygon = PackedVector2Array([
			Vector2(0, 0),
			Vector2(image.get_width(), 0),
			Vector2(image.get_width(), image.get_height()),
			Vector2(0, image.get_height())
		])
		polygons = [bounding_polygon]
	
	var main_polygon = polygons[0]
	
	var center_offset = Vector2(image.get_width() / 2.0, image.get_height() / 2.0)
	var adjusted_polygon = PackedVector2Array()
	for point in main_polygon:
		adjusted_polygon.append(point - center_offset)
	
	var scene_name = _filename_to_scene_name(texture_filename)
	var scene_path = "res://scenes/items/" + scene_name + ".tscn"
	
	var item_enum_value = _get_item_enum_value(item_name)
	var uses_key = item_enum_value == -1 or csv_data.is_empty()
	
	var scene_content = _build_scene_content(
		texture_path,
		texture_filename,
		item_name,
		item_enum_value,
		uses_key,
		adjusted_polygon,
		image.get_width(),
		image.get_height()
	)
	
	var file = FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		printerr("Error: Could not write scene file: ", scene_path)
		return
	
	file.store_string(scene_content)
	file.close()
	
	print("Generated scene: ", scene_path)

func _filename_to_scene_name(filename: String) -> String:
	var base_name = filename.get_basename()
	base_name = base_name.replace("object_", "")
	base_name = base_name.replace("obect_", "")
	
	var parts = base_name.split("_")
	var scene_name = ""
	for part in parts:
		if part.length() > 0:
			scene_name += part.capitalize()
	
	return scene_name

func _filename_to_item_name(filename: String) -> String:
	var base_name = filename.get_basename()
	base_name = base_name.replace("object_", "")
	base_name = base_name.replace("obect_", "")
	
	var parts = base_name.split("_")
	var item_name = ""
	for part in parts:
		if part.length() > 0:
			if item_name.length() > 0:
				item_name += " "
			item_name += part.capitalize()
	
	return item_name

func _get_item_enum_value(item_name: String) -> int:
	var enum_map = {
		"Antlers": 0,
		"Pinecorn": 1,
		"Eyes": 2,
		"Buttons": 3,
		"Monocle": 4,
		"dog bone earring": 5,
		"cat ears": 6
	}
	
	if enum_map.has(item_name):
		return enum_map[item_name]
	return -1

func _build_scene_content(
	texture_path: String,
	texture_filename: String,
	item_name: String,
	item_enum_value: int,
	uses_key: bool,
	polygon: PackedVector2Array,
	image_width: int,
	image_height: int
) -> String:
	var drag_element_scene_uid = "uid://10u3iwnvbokh"
	var item_points_scene_uid = "uid://d3fshonmxcdsv"
	
	var scene_name = _filename_to_scene_name(texture_filename)
	
	var polygon_string = "PackedVector2Array("
	for i in range(polygon.size()):
		var point = polygon[i]
		polygon_string += str(point.x) + ", " + str(point.y)
		if i < polygon.size() - 1:
			polygon_string += ", "
	polygon_string += ")"
	
	var item_points_config = ""
	if uses_key:
		item_points_config = "\nkey = \"" + item_name + "\""
	else:
		item_points_config = "\nitem_name = " + str(item_enum_value)
	
	var content = """[gd_scene format=3]

[ext_resource type="PackedScene" uid=\"""" + drag_element_scene_uid + """\" path="res://Prefabs/DragElement.tscn" id="1_dragelem"]
[ext_resource type="Texture2D" path=\"""" + texture_path + """\" id="2_texture"]
[ext_resource type="PackedScene" uid=\"""" + item_points_scene_uid + """\" path="res://scenes/item_points.tscn" id="3_itempoints"]

[node name=\"""" + scene_name + """\" type="Node2D" unique_id=""" + str(_generate_unique_id()) + """]

[node name="DragElement" parent="." unique_id=""" + str(_generate_unique_id()) + """ instance=ExtResource("1_dragelem")]
scale = Vector2(1, 1)

[node name="ItemPoints" parent="DragElement" unique_id=""" + str(_generate_unique_id()) + """ instance=ExtResource("3_itempoints")]
position = Vector2(-1, 0)""" + item_points_config + """

[node name="Sprite2D" type="Sprite2D" parent="DragElement" unique_id=""" + str(_generate_unique_id()) + """]
texture = ExtResource("2_texture")

[node name="CollisionPolygon2D" type="CollisionPolygon2D" parent="DragElement" unique_id=""" + str(_generate_unique_id()) + """]
polygon = """ + polygon_string + """
"""
	
	return content

func _generate_unique_id() -> int:
	return randi() % 2147483647
