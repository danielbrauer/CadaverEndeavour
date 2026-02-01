extends Area2D
class_name InteractiveObject

# --- New Physics Variables ---
var velocity : Vector2 = Vector2.ZERO
var friction : float = 20
var min_stop_speed : float = 10

# --- State Variables ---
var beingDragged : bool = false
var is_inside_dropable : bool = true
var is_dying : bool = false 
var grace_period : float = 0.75 

# Timer to prevent the object from "dying" the moment it spawns
var spawn_protection : float = 0.5 
# We store the initial max time to reset it later
var max_spawn_protection : float = 0.5 

# Store the tween to cancel it later
var death_tween : Tween 

# --- New: Store Start Position ---
var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	max_spawn_protection = spawn_protection
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Reduce spawn protection timer at the start
	if AppStateManager.currentState != AppStateManager.States.GAME:
		return
	if spawn_protection > 0:
		spawn_protection -= delta
		# We return here so we don't run death logic while protected
		return 

	# --- RESCUE LOGIC ---
	if beingDragged and is_dying:
		revive_object()

	# If dying, skip movement and logic
	if is_dying:
		return

	# --- Movement Logic ---
	if velocity.length() > 0:
		global_position += velocity * delta
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		if velocity.length() < min_stop_speed:
			velocity = Vector2.ZERO
	
	# --- Death Logic ---
	if !is_inside_dropable and !beingDragged:
		darkenAndShrink()

# --- Death/Revive Logic ---

func darkenAndShrink() -> void:
	if is_dying: return
	is_dying = true
	
	death_tween = create_tween()
	death_tween.set_parallel(true)
	
	# Animate to dark grey and half scale
	death_tween.tween_property(self, "modulate", Color(0.1, 0.1, 0.1, 1.0), grace_period)
	death_tween.tween_property(self, "scale", Vector2(0.5, 0.5), grace_period)
	
	death_tween.finished.connect(_perform_disable)

func revive_object() -> void:
	if death_tween:
		death_tween.kill()
	
	is_dying = false
	
	# Snap visual properties back to normal
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(1, 1)
	
	# Reset interaction states
	input_pickable = true
	monitoring = true
	monitorable = true

func _perform_disable() -> void:
	# 2. Disable interactions
	monitoring = false
	monitorable = false
	input_pickable = false 
	set_process(false) # Stop checking logic temporarily
	
	collision_layer = 0
	collision_mask = 0
	
	# 3. Wait 0.5 seconds, then Respawn
	get_tree().create_timer(0.5).timeout.connect(_respawn_at_start)

func _respawn_at_start() -> void:
	# 4. Teleport back to start
	global_position = start_position
	velocity = Vector2.ZERO # Stop sliding
	
	# 5. Reset Visuals
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(1, 1)
	
	# 6. Reset State Flags
	is_dying = false
	beingDragged = false
	
	# 7. Reset Protection so it doesn't die instantly upon reappearing
	spawn_protection = max_spawn_protection 
	
	# 8. Re-enable Physics/Process
	input_pickable = true
	# Reset your collision layers here (Adjust bits as necessary for your game)
	collision_layer = 1 
	collision_mask = 1
	monitoring = true
	monitorable = true
	set_process(true)
	
	# 9. Check if we spawned inside a valid area immediately
	force_update_containment()

# --- Collision Logic ---

func _on_body_entered(body: Node2D) -> void:
	containmentEntryCheck(body)

func _on_body_exit(body: Node2D) -> void:
	containmentExitCheck(body)

func containmentEntryCheck(body: Node2D) -> void:
	if !body.is_in_group("ContainmentArea"): return
	is_inside_dropable = true

func containmentExitCheck(body: Node2D) -> void:
	if !body.is_in_group("ContainmentArea"): return
	is_inside_dropable = false
	
func force_update_containment() -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	is_inside_dropable = false 
	for body in bodies:
		if body.is_in_group("ContainmentArea"):
			is_inside_dropable = true
			break
	
	if is_inside_dropable and is_dying:
		revive_object()
