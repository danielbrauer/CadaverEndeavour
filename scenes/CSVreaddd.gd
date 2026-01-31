extends Node2D
func _ready():
	# Load the data
	var item_database = CSVReader.read_csv_to_dict("res://resources/testDoc.csv")
	
	# Access data using the ID (first column by default)
	if "sword_01" in item_database:
		var sword = item_database["sword_01"]
		print(sword["name"]) # Prints: Iron Sword
		print(sword["cost"]) # Prints: 150
