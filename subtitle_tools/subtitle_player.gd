extends Node2D

@export var config: SubtitleConfig

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var subtitle_label: Label = $Container/SubtitleLabel

var segments: Array = []
var current_segment_index: int = -1
var audio_file_path: String = ""
var camera: Camera2D

func _ready() -> void:
	if not audio_player:
		push_error("AudioStreamPlayer node not found")
		return
	if not subtitle_label:
		push_error("SubtitleLabel node not found")
		return
	
	var parent_node = get_parent()
	while parent_node:
		if parent_node is Camera2D:
			camera = parent_node
			break
		parent_node = parent_node.get_parent()
	
	audio_player.finished.connect(_on_audio_finished)
	
	if config != null:
		if config.audio_stream != null:
			audio_player.stream = config.audio_stream
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
			
	play_audio()

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

func play_audio() -> void:
	if audio_player.stream == null:
		push_error("No audio stream loaded")
		return
	
	current_segment_index = -1
	subtitle_label.text = ""
	audio_player.play()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not audio_player.playing:
		return
	
	if camera:
		position = camera.offset
	
	var current_time = audio_player.get_playback_position()
	var segment = _get_current_segment(current_time)
	
	if not segment.is_empty():
		var segment_index = segments.find(segment)
		if segment_index != current_segment_index:
			current_segment_index = segment_index
			subtitle_label.text = segment["text"].strip_edges()
	else:
		if current_segment_index != -1:
			current_segment_index = -1
			subtitle_label.text = ""

func _get_current_segment(time: float) -> Dictionary:
	for segment in segments:
		if time >= segment["start"] and time <= segment["end"]:
			return segment
	return {}

func _on_audio_finished() -> void:
	subtitle_label.text = ""
	current_segment_index = -1

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
