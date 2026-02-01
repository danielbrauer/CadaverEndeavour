@icon("res://icon.svg")

extends Node
class_name Person

enum PersonType {
	BABY,
	WIFE,
	SON
}

static var _enum_to_string: Dictionary = {
	PersonType.BABY: "Baby",
	PersonType.WIFE: "Wife",
	PersonType.SON: "Son"
}

@export var person: PersonType = PersonType.BABY

var baseline_points: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var csv = CSVReader.read_csv_to_dict("res://resources/people.csv")
	var key = _enum_to_string[person]
	if !csv.has(key):
		print("Missing key ", key, " in CSV: ", csv)
		return
	var preferences = csv[key]
	
	for csv_key in preferences:
		if csv_key == "BASELINE":
			continue
		if !PointType.is_valid_key(csv_key):
			continue
		var node : Preference = preload("res://scenes/preference.tscn").instantiate()
		node.preference_multiplier = preferences[csv_key]
		node.preference_type = PointType.from_string(csv_key)
		self.add_child(node)
	if !preferences.has("BASELINE"):
		print("Missing BASELINE: ", preferences)
	self.baseline_points = preferences["BASELINE"]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("drag"):
		print("score: ", calculate_score())

func collect_preferences() -> Array[Preference] :
	var results : Array[Preference] = []
	for child in self.get_children():
		if child is Preference:
			results.append(child)
	return results

func collect_points() -> Array[ScorePoint] :
	#get guy
	var nodes = get_tree().get_nodes_in_group("ScorePoint")
	var results : Array[ScorePoint] = []
	results.assign(nodes)
	return results

func calculate_score() -> float:
	var prefs = collect_preferences()
	var points = collect_points()
	var score = self.baseline_points
	for pref in prefs:
		for point in points:
			if point.point_type == pref.preference_type:
				score += pref.preference_multiplier*point.point_amount
	return score
