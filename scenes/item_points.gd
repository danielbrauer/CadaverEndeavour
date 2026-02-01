extends Node2D

@export var key: String

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
	if Engine.is_editor_hint():
		return
	var csv = CSVReader.read_csv_to_dict("res://resources/items.csv")
	if !csv.has(self.key):
		print("Missing key ", self.key, " in CSV: ", csv)
		return
	var points = csv[self.key]
	
	for key in enum_map.keys():
		if !points.has(key):
			print("Missing key ", key, " in CSV entry: ", points)
			continue
		var node : ScorePoint = preload("res://scenes/point.tscn").instantiate()
		node.point_amount = points[key]
		node.point_type = enum_map[key]
		self.add_child(node)
