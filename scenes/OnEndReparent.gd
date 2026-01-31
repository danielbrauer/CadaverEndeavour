extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate = Color(Color.MEDIUM_ORCHID,0.7)


#TODO: Reformat this
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(DraggingManager.is_dragging):
		visible = true
	else:
		visible = false
