@icon("res://icon.svg")

extends Node
class_name Person

@export var tears: Node2D
@export var hearts: Node2D

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
	pass

func collect_preferences() -> Array[Preference]:
	var results: Array[Preference] = []
	for child in get_children():
		if child is Preference:
			results.append(child)
	return results

func _is_item_in_attachment_area(item: Node) -> bool:
	if not item:
		return false
	
	var parent = item.get_parent()
	if parent and (parent.is_in_group("Attachment") or "Attachment" in parent.name):
		return true
	
	var attachment_scenes = get_tree().get_nodes_in_group("Attachment")
	for attachment in attachment_scenes:
		if attachment.has_node("Area2D"):
			var area = attachment.get_node("Area2D")
			if area and item in area.get_overlapping_areas():
				return true
	
	return false

func calculate_score() -> float:
	var points_by_type: Dictionary = {}
	
	for point in get_tree().get_nodes_in_group("ScorePoint"):
		if point is ScorePoint:
			var item_parent = point.get_parent()
			var is_attached = _is_item_in_attachment_area(item_parent)
			
			if is_attached:
				var point_type = point.point_type
				if not points_by_type.has(point_type):
					points_by_type[point_type] = 0.0
				points_by_type[point_type] += point.point_amount
	
	for obj in get_tree().get_nodes_in_group("Grabbable"):
		if obj is InteractiveObject:
			var interactive: InteractiveObject = obj
			var is_attached = _is_item_in_attachment_area(interactive)
			
			if is_attached and interactive.types.size() > 0:
				for i in range(interactive.types.size()):
					var point_type = interactive.types[i]
					var amount = interactive.amounts[i] if i < interactive.amounts.size() else 1.0
					if not points_by_type.has(point_type):
						points_by_type[point_type] = 0.0
					points_by_type[point_type] += amount
	
	var score = baseline_points
	for child in get_children():
		if child is Preference:
			var pref: Preference = child
			if points_by_type.has(pref.preference_type):
				score += pref.preference_multiplier * points_by_type[pref.preference_type]
	
	if tears:
		tears.visible = score < 0.0
	if hearts:
		hearts.visible = score > 1.0
	
	return score
