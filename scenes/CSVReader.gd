class_name CSVReader
extends Node

# Reads a CSV file and returns a Dictionary of Dictionaries.
# unique_id_column: The index of the column to use as the main Dictionary key (default is 0).
static func read_csv_to_dict(path: String, unique_id_column: int = 0) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		printerr("Error: Could not open file at: ", path)
		return {}

	var result = {}
	
	# 1. Get headers (keys) from the first line
	var headers = file.get_csv_line()
	
	# 2. Loop through the rest of the file
	while file.get_position() < file.get_length():
		var values = file.get_csv_line()
		
		# Safety check: Ensure the row has the same number of columns as the header
		if values.size() != headers.size():
			continue 
			
		var row_dict = {}
		
		# 3. Map values to header keys
		for i in range(headers.size()):
			var key = headers[i]
			var value = values[i]
			
			# Optional: Auto-convert numbers
			if value.is_valid_float():
				value = value.to_float()
			elif value.is_valid_int():
				value = value.to_int()
				
			row_dict[key] = value
		
		# 4. Use the specified column as the main key for the big dictionary
		# (We convert the ID to a String to be safe, or keep it as is)
		var main_key = row_dict[headers[unique_id_column]]
		result[main_key] = row_dict
		
	return result
