extends Resource
class_name SubtitleConfig

@export var audio_stream: AudioStream
@export var transcription_path: String = ""

func get_audio_path() -> String:
	if audio_stream == null:
		return ""
	return audio_stream.resource_path

func get_transcription_path() -> String:
	if not transcription_path.is_empty():
		return transcription_path
	
	var audio_path = get_audio_path()
	if audio_path.is_empty():
		return ""
	
	var base_path = audio_path.get_base_dir()
	var base_name = audio_path.get_file().get_basename()
	return base_path.path_join(base_name + ".json")

func is_valid() -> bool:
	return audio_stream != null and not transcription_path.is_empty()
