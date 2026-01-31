extends Resource
class_name DragObjectData

@export_group("Visuals")
@export var sprite_color: Color = Color.WHITE
@export var death_color: Color = Color(0.1, 0.1, 0.1)

@export_group("Physics")
@export var friction: float = 8.0
@export var grace_period: float = 0.75
@export var min_stop_speed: float = 5.0