extends Node

class_name PointType

enum Type {
	Hunting = 0,
	BodyPart = 1,
	Nature = 2,
	Dog = 3,
	Cat = 4,
	Eyes = 5,
	Ears = 6
}

static var _string_to_enum: Dictionary = {
	"Hunting": Type.Hunting,
	"BodyPart": Type.BodyPart,
	"Nature": Type.Nature,
	"Dog": Type.Dog,
	"Cat": Type.Cat,
	"Eyes": Type.Eyes,
	"Ears": Type.Ears
}

static func from_string(key: String) -> Type:
	if _string_to_enum.has(key):
		return _string_to_enum[key]
	return Type.Hunting

static func is_valid_key(key: String) -> bool:
	return _string_to_enum.has(key)
