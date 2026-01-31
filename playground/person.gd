extends Node

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
	var score = 0.0
	for pref in prefs:
		for point in points:
			if point.point_type == pref.preference_type:
				score += pref.preference_multiplier*point.point_amount
	return score
