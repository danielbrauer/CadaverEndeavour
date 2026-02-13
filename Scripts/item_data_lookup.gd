class_name ItemDataLookup
extends RefCounted

static var _mapping_cache: Dictionary = {}
static var _csv_cache: Dictionary = {}

static func _load_mapping() -> Dictionary:
	if not _mapping_cache.is_empty():
		return _mapping_cache
	
	var file = FileAccess.open("res://resources/texture_item_mapping.json", FileAccess.READ)
	if file == null:
		printerr("Error: Could not open texture_item_mapping.json")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		printerr("Error: Failed to parse texture_item_mapping.json: ", json.get_error_message())
		return {}
	
	_mapping_cache = json.get_data()
	return _mapping_cache

static func _load_csv_data() -> Dictionary:
	if not _csv_cache.is_empty():
		return _csv_cache
	
	_csv_cache = CSVReader.read_csv_to_dict("res://resources/items.data")
	return _csv_cache

static func get_item_data_from_texture(texture_path: String) -> Dictionary:
	var mapping = _load_mapping()
	var csv_data = _load_csv_data()
	
	if mapping.is_empty() or csv_data.is_empty():
		return {}
	
	var texture_filename = texture_path.get_file()
	if not mapping.has(texture_filename):
		printerr("Error: Texture filename '", texture_filename, "' not found in mapping")
		return {}
	
	var item_name = mapping[texture_filename]
	if not csv_data.has(item_name):
		printerr("Error: Item name '", item_name, "' not found in CSV data")
		return {}
	
	return csv_data[item_name]
