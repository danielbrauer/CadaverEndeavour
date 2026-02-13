extends Node2D

# ---------------- SETTINGS ---------------- #
# "How much" the camera follows. 
# 0.1 = subtle lean. 0.5 = follows mouse halfway.
@export_range(0.0, 1.0) var lean_strength: float = 0.2

# The max pixels the camera is allowed to move away from the center.
@export var max_lean_distance: float = 200.0

# Higher = Snappier. Lower = Smoother/Slower.
@export var smoothing: float = 5.0

# ---------------- INTERNAL ---------------- #
var camera: Camera2D

func _ready() -> void:
	# 1. Grab the parent node and make sure it's a Camera
	var parent = get_parent()
	if parent is Camera2D:
		camera = parent
	else:
		push_error("This script must be a CHILD of a Camera2D node!")
		set_process(false) # Stop the script if setup is wrong

func _process(delta: float) -> void:
	if not camera: return
	if AppStateManager.currentState != AppStateManager.States.GAME && AppStateManager.currentState != AppStateManager.States.GAMEOVER && AppStateManager.currentState != AppStateManager.States.FREEPLAY:
		return

	# 2. Get Mouse Position relative to the center of the screen
	var viewport_center = get_viewport_rect().size / 2
	var mouse_pos = get_viewport().get_mouse_position()
	var dist_from_center = mouse_pos - viewport_center

	# 3. Calculate target offset
	var target_offset = dist_from_center * lean_strength

	# 4. Clamp the distance (Limit how far it can go)
	target_offset = target_offset.limit_length(max_lean_distance)

	# 5. Apply the offset to the PARENT Camera
	camera.offset = camera.offset.lerp(target_offset, smoothing * delta)
