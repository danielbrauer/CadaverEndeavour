extends Node2D

func _ready() -> void:
	call_deferred("run_all_tests")

func run_all_tests() -> void:
	test_csv_loading()
	test_preferences_loading()
	test_scoring_algorithm()

func test_csv_loading() -> void:
	var items_csv = CSVReader.read_csv_to_dict("res://resources/items.csv")
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.csv")

func test_preferences_loading() -> void:
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.csv")
	var all_loaded = true
	
	for child in get_children():
		if child is Person:
			var person: Person = child
			var person_key = Person._enum_to_string[person.person]
			
			if !people_csv.has(person_key):
				all_loaded = false
				continue
			
			var prefs = person.collect_preferences()
			if prefs.is_empty():
				var pref_count = 0
				for person_child in person.get_children():
					if person_child is Preference:
						pref_count += 1
				if pref_count == 0:
					all_loaded = false

func test_scoring_algorithm() -> void:
	var items_csv = CSVReader.read_csv_to_dict("res://resources/items.csv")
	var people_csv = CSVReader.read_csv_to_dict("res://resources/people.csv")
	
	test_case_1_single_item(items_csv, people_csv)
	test_case_2_multiple_items(items_csv, people_csv)
	test_case_3_zero_negative_preferences(items_csv, people_csv)
	test_case_4_all_family_members(items_csv, people_csv)

func test_case_1_single_item(items_csv: Dictionary, people_csv: Dictionary) -> void:
	var antlers_data = items_csv.get("Antlers", {})
	var son_data = people_csv.get("Son", {})
	
	if antlers_data.is_empty() or son_data.is_empty():
		return
	
	var expected_score = son_data.get("BASELINE", 0)
	for key in antlers_data:
		if key != "Item" and PointType.is_valid_key(key):
			expected_score += son_data.get(key, 0) * antlers_data.get(key, 0)
	
	var mock_points = create_mock_scorepoints(antlers_data)
	var actual_score = calculate_score_with_points(son_data, mock_points)

func test_case_2_multiple_items(items_csv: Dictionary, people_csv: Dictionary) -> void:
	var antlers_data = items_csv.get("Antlers", {})
	var eyes_data = items_csv.get("Eyes", {})
	var son_data = people_csv.get("Son", {})
	
	if antlers_data.is_empty() or eyes_data.is_empty() or son_data.is_empty():
		return
	
	var all_items_data = {}
	for key in antlers_data:
		if key == "Item":
			continue
		var combined_value = antlers_data.get(key, 0) + eyes_data.get(key, 0)
		all_items_data[key] = combined_value
	
	var expected_score = son_data.get("BASELINE", 0)
	for key in all_items_data:
		if PointType.is_valid_key(key):
			expected_score += son_data.get(key, 0) * all_items_data[key]
	
	var mock_points = create_mock_scorepoints(antlers_data)
	mock_points.append_array(create_mock_scorepoints(eyes_data))
	var actual_score = calculate_score_with_points(son_data, mock_points)

func test_case_3_zero_negative_preferences(items_csv: Dictionary, people_csv: Dictionary) -> void:
	var pinecorn_data = items_csv.get("Pinecorn", {})
	var wife_data = people_csv.get("Wife", {})
	
	if pinecorn_data.is_empty() or wife_data.is_empty():
		return
	
	var expected_score = wife_data.get("BASELINE", 0)
	expected_score += wife_data.get("BodyPart", 0) * pinecorn_data.get("BodyPart", 0)
	expected_score += wife_data.get("Nature", 0) * pinecorn_data.get("Nature", 0)
	
	var mock_points = create_mock_scorepoints(pinecorn_data)
	var actual_score = calculate_score_with_points(wife_data, mock_points)

func test_case_4_all_family_members(items_csv: Dictionary, people_csv: Dictionary) -> void:
	var antlers_data = items_csv.get("Antlers", {})
	
	if antlers_data.is_empty():
		return
	
	var mock_points = create_mock_scorepoints(antlers_data)
	var all_passed = true
	
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
			
			if abs(actual_score - expected_score) >= 0.001:
				all_passed = false

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
