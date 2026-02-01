@icon("res://icon.svg")

extends Node
class_name Person

@export var key: String

# Note: Loaded from CSV
var baseline_points: float = 0.0

var enum_map = { 
	"Hunting": PointType.PointType.Hunting,
	"BodyPart": PointType.PointType.BodyPart,
	"Nature": PointType.PointType.Nature,
	"Dog": PointType.PointType.Dog,
	"Cat": PointType.PointType.Cat,
	"Eyes": PointType.PointType.Eyes,
	"Ears": PointType.PointType.Ears
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var csv = CSVReader.read_csv_to_dict("res://resources/people.csv")
	if !csv.has(self.key):
		print("Missing key ", self.key, " in CSV: ", csv)
		return
	var preferences = csv[self.key]
	
	for key in enum_map.keys():
		if !preferences.has(key):
			print("Missing key ", key, " in CSV entry: ", preferences)
			continue
		var node : Preference = preload("res://scenes/preference.tscn").instantiate()
		node.preference_multiplier = preferences[key]
		node.preference_type = enum_map[key]
		self.add_child(node)
	if !preferences.has("BASELINE"):
		print("Missing BASELINE: ", preferences)
	self.baseline_points = preferences["BASELINE"]


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("drag"):
		print("score: ", calculate_score())

func collect_preferences() -> Array[Preference] :
	var results : Array[Preference] = []
	results.assign(self.find_children("*", "Preference"))
	return results

func collect_points() -> Array[ScorePoint] :
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
