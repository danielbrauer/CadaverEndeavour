extends Area2D

# --- New Physics Variables ---
var velocity : Vector2 = Vector2.ZERO
var friction : float = 4.0  # Higher = stops faster (Sand), Lower = slides longer (Ice)
var min_stop_speed : float = 5.0

# --- Existing Variables ---
var draggable : bool = false
var is_inside_dropable : bool

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)

func _process(delta: float) -> void:
	# Only apply momentum if we are actually moving
	if velocity.length() > 0:
		# 1. Move the object based on current velocity
		global_position += velocity * delta
		
		# 2. Apply Friction (slow down over time)
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		
		# 3. Force stop if moving very slowly (saves CPU)
		if velocity.length() < min_stop_speed:
			velocity = Vector2.ZERO

# --- Existing Logic ---

func _on_body_exit(body:StaticBody2D) -> void:
	if !body.is_in_group("Attachment"):
		return
	
	is_inside_dropable = false
	body.modulate = Color(Color.CORNFLOWER_BLUE, 0.7)
	DraggingManager.goalBody = null
	
func _on_body_entered(body:StaticBody2D):
	if !body.is_in_group("Attachment"):
		return
	
	is_inside_dropable = true
	body.modulate = Color(Color.REBECCA_PURPLE, 1)
	DraggingManager.goalBody = body
