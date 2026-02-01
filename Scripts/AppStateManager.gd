extends Node

enum States {MENU,INTRO,GAME,GAMEOVER, ENDSCREEN}

static func state_to_string(state: States) -> String:
	match state:
		States.MENU:
			return "MENU"
		States.INTRO:
			return "INTRO"
		States.GAME:
			return "GAME"
		States.GAMEOVER:
			return "GAMEOVER"
		States.ENDSCREEN:
			return "ENDSCREEN"
		_:
			return "UNKNOWN"

var currentState : States = States.MENU:
	set(value):
		if currentState != value:
			var old_state = currentState
			currentState = value
			call_deferred("on_transition", old_state, currentState)

var title_screen: Node = null
var main_game: Node = null
var end_screen: Node = null

var game_manager: Node = null
var on_game_over: Node = null
var attachment_scene: Node = null
var dead_guy_container: Node = null

var animation_delay: float = 2.0
var end_screen_delay: float = 3.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_find_scene_nodes")
	call_deferred("_initialize_state")
	if AudioManager:
		AudioManager.OnMainAudioFinished.connect(_on_main_audio_finished)
		
func _find_scene_nodes() -> void:
	var main_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if not main_scene:
		return
	
	title_screen = main_scene.get_node_or_null("TitleScreen")
	main_game = main_scene.get_node_or_null("Main Game")
	end_screen = main_scene.get_node_or_null("EndScreen")
	
	if main_game:
		game_manager = main_game.get_node_or_null("GameMaanger")
		on_game_over = main_game.get_node_or_null("Ongameendanimator")
		attachment_scene = main_game.get_node_or_null("Node2D/Animation/Node2D2/Guyy/Guyyyyyyy/AttachmentScene2")
		
		if game_manager and game_manager.has_method("get") and game_manager.get("animation_delay"):
			animation_delay = game_manager.animation_delay
		if on_game_over and on_game_over.has_method("get") and on_game_over.get("end_screen_delay"):
			end_screen_delay = on_game_over.end_screen_delay
	
	if end_screen:
		dead_guy_container = end_screen.get_node_or_null("Coffin/DeadGuyContainer")
		if not dead_guy_container:
			dead_guy_container = end_screen.find_child("DeadGuyContainer", true, false)

func _initialize_state() -> void:
	_handle_transition_to_menu(States.MENU)

func _on_main_audio_finished() -> void:
	request_state_change(States.GAMEOVER)

func request_state_change(new_state: States) -> void:
	if currentState != new_state:
		currentState = new_state

func on_transition(old_state: States, new_state: States) -> void:
	match new_state:
		States.MENU:
			await _handle_transition_to_menu(old_state)
		States.INTRO:
			await _handle_transition_to_intro(old_state)
		States.GAME:
			await _handle_transition_to_game(old_state)
		States.GAMEOVER:
			await _handle_transition_to_gameover(old_state)
		States.ENDSCREEN:
			await _handle_transition_to_endscreen(old_state)

func _handle_transition_to_menu(old_state: States) -> void:
	if not title_screen or not is_instance_valid(title_screen):
		_find_scene_nodes()
	
	_show_scene(title_screen)
	_hide_scene(main_game)
	_hide_scene(end_screen)
	
	if AudioManager:
		if not AudioManager.is_node_ready():
			await AudioManager.ready
		await AudioManager.transition_to_menu()

func _handle_transition_to_intro(old_state: States) -> void:
	if not main_game or not is_instance_valid(main_game):
		_find_scene_nodes()
	
	_hide_scene(title_screen)
	_show_scene(main_game)
	_hide_scene(end_screen)
	
	if not AudioManager:
		return
	
	await AudioManager.transition_to_intro()
	
	await get_tree().create_timer(animation_delay).timeout
	request_state_change(States.GAME)

func _handle_transition_to_game(old_state: States) -> void:
	_hide_scene(title_screen)
	_show_scene(main_game)
	_hide_scene(end_screen)
	
	if AudioManager:
		AudioManager.transition_to_game()

func _handle_transition_to_gameover(old_state: States) -> void:
	_hide_scene(title_screen)
	_show_scene(main_game)
	_hide_scene(end_screen)
	
	if AudioManager:
		AudioManager.transition_to_gameover()
	
	if attachment_scene:
		var area_2d = attachment_scene.get_node_or_null("Area2D")
		if area_2d:
			var bodies: Array[Area2D] = area_2d.get_overlapping_areas()
			for body in bodies:
				if body.is_in_group("Grabbable"):
					_stop_animations(body)
					body.reparent(attachment_scene)
					call_deferred("_stop_animations", body)
					body.collision_layer = 0
					body.collision_mask = 0
	
	if on_game_over:
		var deadguy: Node2D = null
		var out_of_screen_pos_y: float = 1000.0
		
		if "deadguy" in on_game_over:
			var deadguy_ref = on_game_over.deadguy
			if deadguy_ref is NodePath:
				deadguy = on_game_over.get_node_or_null(deadguy_ref)
			elif deadguy_ref is Node2D:
				deadguy = deadguy_ref
		
		if "outOfScreenPosY" in on_game_over:
			out_of_screen_pos_y = on_game_over.outOfScreenPosY
		
		if not deadguy or out_of_screen_pos_y == 0.0:
			request_state_change(States.ENDSCREEN)
			return
		
		var tween: Tween = on_game_over.create_tween()
		tween.tween_property(deadguy, "global_position:y", out_of_screen_pos_y, 1.0)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_IN)
		tween.tween_interval(end_screen_delay)
		
		var parent = on_game_over.get_parent()
		if parent is CanvasItem:
			tween.tween_property(parent, "modulate", Color.BLACK, 1.5)
		
		await tween.finished
		request_state_change(States.ENDSCREEN)
	else:
		request_state_change(States.ENDSCREEN)

func _stop_animations(node: Node) -> void:
	if not node:
		return
	var animation_players = node.find_children("*", "AnimationPlayer", true, false)
	for anim_player in animation_players:
		if anim_player is AnimationPlayer:
			anim_player.stop()
			anim_player.seek(0.0, true)
	if node is AnimationPlayer:
		node.stop()
		node.seek(0.0, true)

func _handle_transition_to_endscreen(old_state: States) -> void:
	_hide_scene(title_screen)
	_hide_scene(main_game)
	_show_scene(end_screen)
	
	if end_screen and end_screen.has_method("_start_animation"):
		end_screen._start_animation()
	
	if AudioManager:
		await AudioManager.transition_to_endscreen()
		AudioManager.fade_to_neutral()
	
	if dead_guy_container:
		var dead_guys = get_tree().get_nodes_in_group("DeadGuy")
		if dead_guys and not dead_guys.is_empty():
			var deadguy = dead_guys[0]
			deadguy.reparent(dead_guy_container)
			deadguy.position = Vector2.ZERO
			deadguy.scale = Vector2.ONE
	
	if end_screen and end_screen.has_method("_sequence_family_scores"):
		end_screen._sequence_family_scores()

func _show_scene(scene: Node) -> void:
	if not scene:
		return
	if not is_instance_valid(scene):
		return
	scene.visible = true
	if scene is CanvasItem:
		scene.process_mode = Node.PROCESS_MODE_INHERIT

func _hide_scene(scene: Node) -> void:
	if not scene:
		return
	if not is_instance_valid(scene):
		return
	scene.visible = false
	if scene is CanvasItem:
		scene.process_mode = Node.PROCESS_MODE_DISABLED
