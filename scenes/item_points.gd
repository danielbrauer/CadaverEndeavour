extends Node2D

@export var key: String

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var csv = CSVReader.read_csv_to_dict("res://resources/items.csv")
	if !csv.has(self.key):
		print("Missing key ", self.key, " in CSV: ", csv)
		return
	var points = csv[self.key]
	
	for csv_key in points:
		if !PointType.is_valid_key(csv_key):
			continue
		var node : ScorePoint = preload("res://scenes/point.tscn").instantiate()
		node.point_amount = points[csv_key]
		node.point_type = PointType.from_string(csv_key)
		self.add_child(node)
