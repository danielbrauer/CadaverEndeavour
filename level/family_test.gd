extends Node2D

func _ready() -> void:
	print("=== SCORING SYSTEM DEBUG TESTS ===")
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	test_csv_loading()
	test_preferences_loading()
	test_scoring_algorithm()

func test_csv_loading() -> void:
	print("\n--- Test 1: CSV Loading ---")
	
	var items_csv = CSVReader.read_csv_to_dict("res://resources/items.data")
	print("Items CSV loaded: ", items_csv.size(), " items")
	for item_name in items_csv:
		print("  Item: ", item_name, " -> ", items_csv[item_name])
	
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.data")
	print("People CSV loaded: ", people_csv.size(), " people")
	for person_name in people_csv:
		print("  Person: ", person_name, " -> ", people_csv[person_name])
	
	if items_csv.is_empty():
		push_error("Items CSV is empty!")
	if people_csv.is_empty():
		push_error("People CSV is empty!")

func test_preferences_loading() -> void:
	print("\n--- Test 2: Preferences Loading ---")
	
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.data")
	
	for child in get_children():
		if child is Person:
			var person: Person = child
			var person_key = Person._enum_to_string[person.person]
			print("\nPerson: ", person_key)
			
			if !people_csv.has(person_key):
				push_error("Missing person in CSV: ", person_key)
				continue
			
			var preferences = people_csv[person_key]
			print("  BASELINE: ", preferences.get("BASELINE", "MISSING"))
			print("  Expected preferences from CSV:")
			for key in preferences:
				if key != "Person" and key != "BASELINE" and PointType.is_valid_key(key):
					print("    ", key, ": ", preferences[key])
			
			print("  Person node children count: ", person.get_child_count())
			print("  Person node children:")
			for person_child in person.get_children():
				print("    - ", person_child.name, " (class: ", person_child.get_class(), ", is Preference: ", person_child is Preference, ")")
			
			var prefs = person.collect_preferences()
			print("  Loaded ", prefs.size(), " preferences from Person node:")
			if prefs.is_empty():
				print("    WARNING: No preferences found! Person._ready() may not have run yet.")
				print("    Person baseline_points: ", person.baseline_points)
				print("    Trying alternative method to find preferences...")
				var all_children = person.get_children()
				var pref_count = 0
				for person_child in all_children:
					if person_child is Preference:
						pref_count += 1
						var pref: Preference = person_child
						var type_name = point_type_to_string(pref.preference_type)
						print("      Found via get_children(): ", type_name, ": ", pref.preference_multiplier)
				if pref_count > 0:
					print("    Found ", pref_count, " preferences via get_children() but not via find_children()")
			else:
				for pref in prefs:
					var type_name = point_type_to_string(pref.preference_type)
					print("    ", type_name, ": ", pref.preference_multiplier)

func test_scoring_algorithm() -> void:
	print("\n--- Test 3: Scoring Algorithm Tests ---")
	
	var items_csv = CSVReader.read_csv_to_dict("res://resources/items.data")
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.data")
	
	test_case_1_single_item(items_csv, people_csv)
	test_case_2_multiple_items(items_csv, people_csv)
	test_case_3_zero_negative_preferences(items_csv, people_csv)
	test_case_4_all_family_members(items_csv, people_csv)

func test_case_1_single_item(items_csv: Dictionary, people_csv: Dictionary) -> void:
	print("\n--- Test Case 1: Single Item (Antlers + Son) ---")
	
	var antlers_data = items_csv.get("Antlers", {})
	var son_data = people_csv.get("Son", {})
	
	if antlers_data.is_empty() or son_data.is_empty():
		push_error("Missing data for test case 1")
		return
	
	print("Item: Antlers")
	for key in antlers_data:
		if key != "Item" and PointType.is_valid_key(key):
			print("  ", key, ": ", antlers_data.get(key, 0))
	
	print("Person: Son")
	print("  BASELINE: ", son_data.get("BASELINE", 0))
	for key in antlers_data:
		if key != "Item" and PointType.is_valid_key(key):
			print("  ", key, " preference: ", son_data.get(key, 0))
	
	var expected_score = son_data.get("BASELINE", 0)
	for key in antlers_data:
		if key != "Item" and PointType.is_valid_key(key):
			expected_score += son_data.get(key, 0) * antlers_data.get(key, 0)
	
	print("Expected score: ", expected_score)
	
	var mock_points = create_mock_scorepoints(antlers_data)
	var actual_score = calculate_score_with_points(son_data, mock_points)
	
	print("Calculated score: ", actual_score)
	
	if abs(actual_score - expected_score) < 0.001:
		print("✓ Test Case 1 PASSED")
	else:
		push_error("✗ Test Case 1 FAILED: Expected ", expected_score, " but got ", actual_score)

func test_case_2_multiple_items(items_csv: Dictionary, people_csv: Dictionary) -> void:
	print("\n--- Test Case 2: Multiple Items (Antlers + Eyes + Son) ---")
	
	var antlers_data = items_csv.get("Antlers", {})
	var eyes_data = items_csv.get("Eyes", {})
	var son_data = people_csv.get("Son", {})
	
	if antlers_data.is_empty() or eyes_data.is_empty() or son_data.is_empty():
		push_error("Missing data for test case 2")
		return
	
	var all_items_data = {}
	for key in antlers_data:
		if key == "Item":
			continue
		var combined_value = antlers_data.get(key, 0) + eyes_data.get(key, 0)
		all_items_data[key] = combined_value
	
	print("Combined items (Antlers + Eyes):")
	for key in all_items_data:
		if PointType.is_valid_key(key):
			print("  ", key, ": ", all_items_data[key])
	
	var expected_score = son_data.get("BASELINE", 0)
	for key in all_items_data:
		if PointType.is_valid_key(key):
			expected_score += son_data.get(key, 0) * all_items_data[key]
	
	print("Expected score: ", expected_score)
	
	var mock_points = create_mock_scorepoints(antlers_data)
	mock_points.append_array(create_mock_scorepoints(eyes_data))
	var actual_score = calculate_score_with_points(son_data, mock_points)
	
	print("Calculated score: ", actual_score)
	
	if abs(actual_score - expected_score) < 0.001:
		print("✓ Test Case 2 PASSED")
	else:
		push_error("✗ Test Case 2 FAILED: Expected ", expected_score, " but got ", actual_score)

func test_case_3_zero_negative_preferences(items_csv: Dictionary, people_csv: Dictionary) -> void:
	print("\n--- Test Case 3: Zero/Negative Preferences (Pinecorn + Wife) ---")
	
	var pinecorn_data = items_csv.get("Pinecorn", {})
	var wife_data = people_csv.get("Wife", {})
	
	if pinecorn_data.is_empty() or wife_data.is_empty():
		push_error("Missing data for test case 3")
		return
	
	print("Item: Pinecorn")
	print("  BodyPart: ", pinecorn_data.get("BodyPart", 0), " (negative)")
	print("  Nature: ", pinecorn_data.get("Nature", 0))
	
	print("Person: Wife")
	print("  BASELINE: ", wife_data.get("BASELINE", 0))
	print("  BodyPart preference: ", wife_data.get("BodyPart", 0), " (negative)")
	print("  Nature preference: ", wife_data.get("Nature", 0))
	
	var expected_score = wife_data.get("BASELINE", 0)
	expected_score += wife_data.get("BodyPart", 0) * pinecorn_data.get("BodyPart", 0)
	expected_score += wife_data.get("Nature", 0) * pinecorn_data.get("Nature", 0)
	
	print("Expected score: ", expected_score)
	
	var mock_points = create_mock_scorepoints(pinecorn_data)
	var actual_score = calculate_score_with_points(wife_data, mock_points)
	
	print("Calculated score: ", actual_score)
	
	if abs(actual_score - expected_score) < 0.001:
		print("✓ Test Case 3 PASSED")
	else:
		push_error("✗ Test Case 3 FAILED: Expected ", expected_score, " but got ", actual_score)

func test_case_4_all_family_members(items_csv: Dictionary, people_csv: Dictionary) -> void:
	print("\n--- Test Case 4: All Family Members with Same Item (Antlers) ---")
	
	var antlers_data = items_csv.get("Antlers", {})
	
	if antlers_data.is_empty():
		push_error("Missing data for test case 4")
		return
	
	var mock_points = create_mock_scorepoints(antlers_data)
	
	for child in get_children():
		if child is Person:
			var person: Person = child
			var person_key = Person._enum_to_string[person.person]
			var person_data = people_csv.get(person_key, {})
			
			if person_data.is_empty():
				continue
			
			var expected_score = person_data.get("BASELINE", 0)
			for key in antlers_data:
				if PointType.is_valid_key(key):
					expected_score += person_data.get(key, 0) * antlers_data[key]
			
			var actual_score = calculate_score_with_points(person_data, mock_points)
			
			print("\n", person_key, ":")
			print("  Expected: ", expected_score)
			print("  Calculated: ", actual_score)
			
			if abs(actual_score - expected_score) < 0.001:
				print("  ✓ PASSED")
			else:
				push_error("  ✗ FAILED: Expected ", expected_score, " but got ", actual_score)

func create_mock_scorepoints(item_data: Dictionary) -> Array[ScorePoint]:
	var points: Array[ScorePoint] = []
	
	for key in item_data:
		if key == "Item":
			continue
		if !PointType.is_valid_key(key):
			continue
		
		var point: ScorePoint = ScorePoint.new()
		point.point_type = PointType.from_string(key)
		point.point_amount = item_data[key]
		points.append(point)
	
	return points

func point_type_to_string(point_type: PointType.Type) -> String:
	for key in PointType._string_to_enum:
		if PointType._string_to_enum[key] == point_type:
			return key
	return "Unknown"

func calculate_score_with_points(person_data: Dictionary, points: Array[ScorePoint]) -> float:
	var score = person_data.get("BASELINE", 0)
	
	for point in points:
		var pref_key = point_type_to_string(point.point_type)
		var preference_multiplier = person_data.get(pref_key, 0)
		score += preference_multiplier * point.point_amount
	
	return score
