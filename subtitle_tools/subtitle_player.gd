extends Node2D

@export var config: SubtitleConfig

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var subtitle_label: Label = $Container/SubtitleLabel

var segments: Array = []
var current_segment_index: int = -1
var audio_file_path: String = ""
var camera: Camera2D
var main_audio_player: AudioStreamPlayer = null
var frame_count: int = 0
var was_playing: bool = false
var web_time_offset: float = 1

func _ready() -> void:
	if not audio_player:
		push_error("AudioStreamPlayer node not found")
		return
	if not subtitle_label:
		push_error("SubtitleLabel node not found")
		return
		
	var new_sb = StyleBoxFlat.new()
	new_sb.bg_color = Color.BLACK
	subtitle_label.add_theme_stylebox_override("normal", new_sb)
	
	var parent_node = get_parent()
	while parent_node:
		if parent_node is Camera2D:
			camera = parent_node
			break
		parent_node = parent_node.get_parent()
	
	if AudioManager:
		main_audio_player = AudioManager.main_music_player
		if main_audio_player:
			main_audio_player.finished.connect(_on_audio_finished)
			was_playing = main_audio_player.playing
			if was_playing:
				print("[SubtitlePlayer] Audio already playing at _ready(), position: %f" % main_audio_player.get_playback_position())
	
	if AppStateManager:
		AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
		print("[SubtitlePlayer] Connected to AppStateManager, current state: %s" % AppStateManager.currentState)
	
	if config != null:
		audio_file_path = config.get_audio_path()
		var transcription_path = config.get_transcription_path()
		if not transcription_path.is_empty():
			load_transcription(transcription_path)
	elif audio_player.stream != null:
		var stream_path = audio_player.stream.resource_path
		if not stream_path.is_empty():
			audio_file_path = stream_path
			var base_path = stream_path.get_base_dir()
			var base_name = stream_path.get_file().get_basename()
			var auto_transcription_path = base_path.path_join(base_name + ".json")
			load_transcription(auto_transcription_path)

func load_transcription(json_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open transcription file: " + json_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return false
	
	var data = json.get_data()
	if not data.has("segments"):
		push_error("JSON does not contain 'segments' key")
		return false
	
	segments = data["segments"]
	segments.sort_custom(func(a, b): return a["start"] < b["start"])
	return true

func load_audio(file_path: String) -> bool:
	audio_file_path = file_path
	var audio_stream = load(file_path)
	if audio_stream == null:
		push_error("Failed to load audio file: " + file_path)
		return false
	
	audio_player.stream = audio_stream
	return true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not main_audio_player:
		return
	
	var is_playing = main_audio_player.playing
	
	if not is_playing:
		if was_playing:
			was_playing = false
			print("[SubtitlePlayer] Audio stopped playing, position was: %f" % main_audio_player.get_playback_position())
		if current_segment_index != -1:
			current_segment_index = -1
			subtitle_label.text = ""
		return
	
	if not was_playing and is_playing:
		was_playing = true
		var start_position = main_audio_player.get_playback_position()
		print("[SubtitlePlayer] Audio started playing, position: %f" % start_position)
	
	if camera:
		position = camera.offset
		scale = Vector2.ONE / camera.zoom
	
	frame_count += 1
	var current_time = main_audio_player.get_playback_position()
	
	var is_web = OS.get_name() == "Web"
	var adjusted_time = current_time
	if is_web:
		adjusted_time = current_time + web_time_offset
		if adjusted_time < 0.0:
			adjusted_time = 0.0
	
	if frame_count % 60 == 0:
		if is_web:
			print("[SubtitlePlayer] Playback position: %f, adjusted (web): %f" % [current_time, adjusted_time])
		else:
			print("[SubtitlePlayer] Playback position: %f" % current_time)
	
	var segment = _get_current_segment(adjusted_time)
	
	if not segment.is_empty():
		var segment_index = segments.find(segment)
		if segment_index != current_segment_index:
			var subtitle_text = segment["text"].strip_edges()
			if is_web:
				print("[SubtitlePlayer] Subtitle changed at time %f (adjusted: %f) - Segment [%f - %f]: %s" % [current_time, adjusted_time, segment["start"], segment["end"], subtitle_text])
			else:
				print("[SubtitlePlayer] Subtitle changed at time %f - Segment [%f - %f]: %s" % [current_time, segment["start"], segment["end"], subtitle_text])
			current_segment_index = segment_index
			subtitle_label.text = subtitle_text
	else:
		if current_segment_index != -1:
			print("[SubtitlePlayer] Subtitle cleared at time %f" % current_time)
			current_segment_index = -1
			subtitle_label.text = ""

func _get_current_segment(time: float) -> Dictionary:
	for segment in segments:
		if time >= segment["start"] and time <= segment["end"]:
			return segment
	return {}

func _on_game_state_changed() -> void:
	var state = AppStateManager.currentState
	var state_name = ["MENU", "INTRO", "GAME", "GAMEOVER", "ENDSCREEN"][state]
	var playback_pos = 0.0
	if main_audio_player:
		playback_pos = main_audio_player.get_playback_position()
	print("[SubtitlePlayer] Game state changed to: %s, audio playing: %s, position: %f" % [state_name, main_audio_player.playing if main_audio_player else false, playback_pos])

func _on_audio_finished() -> void:
	print("[SubtitlePlayer] Audio finished")
	subtitle_label.text = ""
	current_segment_index = -1
	was_playing = false

func setup(audio_path: String, transcription_path: String = "") -> bool:
	if transcription_path.is_empty():
		var base_path = audio_path.get_base_dir()
		var base_name = audio_path.get_file().get_basename()
		transcription_path = base_path.path_join(base_name + ".json")
	
	if not load_transcription(transcription_path):
		return false
	
	if not load_audio(audio_path):
		return false
	
	return true
