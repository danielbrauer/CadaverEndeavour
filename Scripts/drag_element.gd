extends Area2D

var draggable : bool = false
var is_inside_dropable = false
var body_ref : StaticBody2D
var offset : Vector2
var initalPos : Vector2
@export var transType : Tween.TransitionType
@export var returnTime : float = 0.2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exited)
	
	
	#HOVER EFFECT
func _on_mouse_enter() -> void:
	if not DraggingManager.is_dragging :
		draggable = true
		scale = Vector2(1.05,1.05)

func _on_mouse_exited() -> void:
	if not DraggingManager.is_dragging :
		
		draggable = false
		scale = Vector2(1,1)


func _on_body_exit(body:StaticBody2D) -> void:
	if !body.is_in_group("Attachment"):
		return
	
	is_inside_dropable = false
	body.modulate = Color(Color.CORNFLOWER_BLUE, 0.7)
	body_ref = body
	
func _on_body_entered(body:StaticBody2D):
	if !body.is_in_group("Attachment"):
		return
	
	is_inside_dropable = true
	body.modulate = Color(Color.REBECCA_PURPLE, 1)
	body_ref = body

	
func _process(delta: float) -> void:
	#TODO: Reparent it to another object with is an object that follows the mouse
	if draggable:
		if Input.is_action_just_pressed("drag"):
			initalPos = global_position
			offset = get_global_mouse_position() - global_position
			DraggingManager.is_dragging = true
		if Input.is_action_pressed("drag"):
			global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released("drag"):
			DraggingManager.is_dragging = false
			var tween = get_tree().create_tween()
			if is_inside_dropable:
				tween.tween_property(self,"position",body_ref.position,returnTime).set_trans(transType).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self,"global_position",initalPos,returnTime).set_trans(transType).set_ease(Tween.EASE_OUT)
				#TODO replace this to that if  nothing is bellow mantains momentum and then falls
			tween.tween_callback(print_done)
		
		
		
#TODO: Object should maybe 
func print_done() -> void:
	print("done")
			
