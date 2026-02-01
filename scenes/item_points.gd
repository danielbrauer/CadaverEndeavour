extends Node2D

enum ItemName {
	ANTLERS,
	PINECORN,
	EYES,
	BUTTONS,
	MONOCLE,
	DOG_BONE_EARRING,
	CAT_EARS
}

static var _enum_to_string: Dictionary = {
	ItemName.ANTLERS: "Antlers",
	ItemName.PINECORN: "Pinecorn",
	ItemName.EYES: "Eyes",
	ItemName.BUTTONS: "Buttons",
	ItemName.MONOCLE: "Monocle",
	ItemName.DOG_BONE_EARRING: "dog bone earring",
	ItemName.CAT_EARS: "cat ears"
}

@export var item_name: ItemName = ItemName.ANTLERS
@export var key: String

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	var csv = CSVReader.read_csv_to_dict("res://resources/items.csv")
	var item_key: String
	if key != "":
		item_key = key
	else:
		item_key = _enum_to_string[item_name]
	if !csv.has(item_key):
		print("Missing key ", item_key, " in CSV: ", csv)
		return
	var csv_points = csv[item_key]
	
	for csv_key in csv_points:
		if !PointType.is_valid_key(csv_key):
			continue
		var node: ScorePoint = preload("res://scenes/point.tscn").instantiate()
		node.point_amount = csv_points[csv_key]
		node.point_type = PointType.from_string(csv_key)
		self.add_child(node)
