extends Node

signal OnMainAudioFinished

enum EndingType {
	NONE,
	HAPPY,
	SAD
}

@export var title_music: AudioStream
@export var main_combined_track: AudioStream
@export var happy_ending: AudioStream
@export var sad_ending: AudioStream
@export var crossfade_duration: float = 0.5
@export var T: float = 10.0

@export var baby_happy_sfx: AudioStream
@export var baby_sad_sfx: AudioStream
@export var wife_happy_sfx: AudioStream
@export var wife_sad_sfx: AudioStream
@export var son_happy_sfx: AudioStream
@export var son_sad_sfx: AudioStream
@export var start_drag_sfx: AudioStream
@export var drop_sfx: AudioStream
@export var coffin_sfx: AudioStream

@onready var loop_player: AudioStreamPlayer = $LoopPlayer
@onready var main_audio_player: AudioStreamPlayer = $MainAudioPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var ending_player_1: AudioStreamPlayer = $EndingPlayer1
@onready var ending_player_2: AudioStreamPlayer = $EndingPlayer2

var current_dominant_ending: EndingType = EndingType.NONE
var early_signal_emitted: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	assert(loop_player != null, "LoopPlayer must be set in scene")
	assert(main_audio_player != null, "MainAudioPlayer must be set in scene")
	assert(sfx_player != null, "SfxPlayer must be set in scene")
	assert(ending_player_1 != null, "EndingPlayer1 must be set in scene")
	assert(ending_player_2 != null, "EndingPlayer2 must be set in scene")
	
	assert(title_music != null, "title_music must be set")
	assert(main_combined_track != null, "main_combined_track must be set")
	assert(happy_ending != null, "happy_ending must be set")
	assert(sad_ending != null, "sad_ending must be set")
	assert(baby_happy_sfx != null, "baby_happy_sfx must be set")
	assert(baby_sad_sfx != null, "baby_sad_sfx must be set")
	assert(wife_happy_sfx != null, "wife_happy_sfx must be set")
	assert(wife_sad_sfx != null, "wife_sad_sfx must be set")
	assert(son_happy_sfx != null, "son_happy_sfx must be set")
	assert(son_sad_sfx != null, "son_sad_sfx must be set")
	assert(start_drag_sfx != null, "start_drag_sfx must be set")
	assert(drop_sfx != null, "drop_sfx must be set")
	assert(coffin_sfx != null, "coffin_sfx must be set")
	
	ending_player_1.stream = happy_ending
	ending_player_2.stream = sad_ending

func transition_to_menu() -> void:
	if not is_node_ready():
		await ready
	if loop_player == null:
		return
	if title_music == null:
		return
	_play_title_music()

func transition_to_intro() -> void:
	if not is_node_ready():
		await ready
	
	if main_audio_player == null:
		return
	
	_play_game_audio()

func transition_to_game() -> void:
	pass

func transition_to_gameover() -> void:
	pass

func transition_to_endscreen() -> void:
	if not is_node_ready():
		await ready
	_stop_game_audio()
	_start_ending_music()

func _play_title_music() -> void:
	if loop_player == null:
		return
	if title_music == null:
		return
	
	_stop_all_audio()
	
	if loop_player.finished.is_connected(_on_title_music_finished):
		loop_player.finished.disconnect(_on_title_music_finished)
	
	loop_player.stream = title_music
	loop_player.volume_db = 0.0
	loop_player.finished.connect(_on_title_music_finished)
	loop_player.play()
	
	await get_tree().process_frame
	await get_tree().process_frame

func _on_title_music_finished() -> void:
	if AppStateManager.currentState == AppStateManager.States.MENU:
		if loop_player.stream == title_music:
			loop_player.play()

func _play_game_audio() -> void:
	_stop_all_audio()
	early_signal_emitted = false
	main_audio_player.stream = main_combined_track
	main_audio_player.play()
	main_audio_player.finished.connect(_on_main_track_finished)

func _stop_game_audio() -> void:
	early_signal_emitted = false
	main_audio_player.stop()

func _stop_all_audio() -> void:
	_stop_game_audio()
	
	main_audio_player.stop()
	loop_player.stop()
	ending_player_1.stop()
	ending_player_2.stop()
	sfx_player.stop()

func _start_ending_music() -> void:
	current_dominant_ending = EndingType.NONE
	ending_player_1.stop()
	ending_player_1.volume_db = -80.0
	if ending_player_1.finished.is_connected(_on_ending_player_1_finished):
		ending_player_1.finished.disconnect(_on_ending_player_1_finished)
	ending_player_1.finished.connect(_on_ending_player_1_finished)
	ending_player_1.play()
	ending_player_2.stop()
	ending_player_2.volume_db = -80.0
	if ending_player_2.finished.is_connected(_on_ending_player_2_finished):
		ending_player_2.finished.disconnect(_on_ending_player_2_finished)
	ending_player_2.finished.connect(_on_ending_player_2_finished)
	ending_player_2.play()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if event is InputEventKey and event.keycode == KEY_P and event.is_released():
		if main_audio_player.playing and main_audio_player.stream:
			var stream_length = main_audio_player.stream.get_length()
			var target_position = stream_length - (5.0 + T)
			if target_position >= 0:
				main_audio_player.seek(target_position)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if main_audio_player.playing and main_audio_player.stream:
		var stream_length = main_audio_player.stream.get_length()
		var current_position = main_audio_player.get_playback_position()
		var time_remaining = stream_length - current_position
		
		if time_remaining <= T and not early_signal_emitted:
			early_signal_emitted = true
			if main_audio_player.finished.is_connected(_on_main_track_finished):
				main_audio_player.finished.disconnect(_on_main_track_finished)
			OnMainAudioFinished.emit()

func _on_main_track_finished() -> void:
	OnMainAudioFinished.emit()

func _on_ending_player_1_finished() -> void:
	if ending_player_1.stream == happy_ending:
		ending_player_1.play()

func _on_ending_player_2_finished() -> void:
	if ending_player_2.stream == sad_ending:
		ending_player_2.play()

func update_ending_music(happy_score: float, sad_score: float, neutral_score: float, person_type: Person.PersonType = Person.PersonType.BABY, custom_crossfade_duration: float = -1.0) -> void:
	var new_dominant = _calculate_dominant_ending(happy_score, sad_score, neutral_score)
	var old_crossfade = crossfade_duration
	if custom_crossfade_duration > 0.0:
		crossfade_duration = custom_crossfade_duration
	_crossfade_to_ending(new_dominant)
	if custom_crossfade_duration > 0.0:
		crossfade_duration = old_crossfade
	_play_character_sfx(person_type, new_dominant)

func fade_to_neutral() -> void:
	_crossfade_to_ending(EndingType.SAD)

func _calculate_dominant_ending(happy_score: float, sad_score: float, neutral_score: float) -> EndingType:
	if happy_score > sad_score:
		return EndingType.HAPPY
	else:
		return EndingType.SAD

func _db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func _set_player_volume_linear(player: AudioStreamPlayer, linear: float) -> void:
	player.volume_db = _linear_to_db(linear)

func _set_ending_player_1_volume_linear(linear: float) -> void:
	ending_player_1.volume_db = _linear_to_db(linear)

func _set_ending_player_2_volume_linear(linear: float) -> void:
	ending_player_2.volume_db = _linear_to_db(linear)

func _crossfade_to_ending(ending_type: EndingType) -> void:
	var ending_changed = ending_type != current_dominant_ending
	
	if not ending_changed:
		return
	
	current_dominant_ending = ending_type
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var player_1_start_linear = _db_to_linear(ending_player_1.volume_db)
	var player_2_start_linear = _db_to_linear(ending_player_2.volume_db)
	
	if ending_type == EndingType.HAPPY:
		if not ending_player_1.playing:
			ending_player_1.play()
		tween.tween_method(_set_ending_player_1_volume_linear, player_1_start_linear, 1.0, crossfade_duration)
		tween.tween_method(_set_ending_player_2_volume_linear, player_2_start_linear, 0.0, crossfade_duration)
	else:
		if not ending_player_2.playing:
			ending_player_2.play()
		tween.tween_method(_set_ending_player_2_volume_linear, player_2_start_linear, 1.0, crossfade_duration)
		tween.tween_method(_set_ending_player_1_volume_linear, player_1_start_linear, 0.0, crossfade_duration)


func _play_character_sfx(person_type: Person.PersonType, ending_type: EndingType) -> void:
	var sfx_stream = _get_character_sfx_stream(person_type, ending_type)
	assert(sfx_stream != null, "SFX stream must be set for person_type and ending_type")
	await get_tree().create_timer(crossfade_duration).timeout
	if sfx_player.finished.is_connected(_on_sfx_finished):
		sfx_player.finished.disconnect(_on_sfx_finished)
	sfx_player.stream = sfx_stream
	if sfx_stream is AudioStream:
		if sfx_stream.has_method("set_loop"):
			sfx_stream.set_loop(false)
	sfx_player.play()

func _on_sfx_finished() -> void:
	pass

func _get_character_sfx_stream(person_type: Person.PersonType, ending_type: EndingType) -> AudioStream:
	match person_type:
		Person.PersonType.BABY:
			if ending_type == EndingType.SAD:
				return baby_sad_sfx
			else:
				return baby_happy_sfx
		Person.PersonType.WIFE:
			if ending_type == EndingType.SAD:
				return wife_sad_sfx
			else:
				return wife_happy_sfx
		Person.PersonType.SON:
			if ending_type == EndingType.SAD:
				return son_sad_sfx
			else:
				return son_happy_sfx
		_:
			return null

func play_start_drag_sfx() -> void:
	sfx_player.stream = start_drag_sfx
	sfx_player.play()

func play_drop_sfx() -> void:
	sfx_player.stream = drop_sfx
	sfx_player.play()

func play_coffin_sfx() -> void:
	sfx_player.stream = coffin_sfx
	sfx_player.play()
