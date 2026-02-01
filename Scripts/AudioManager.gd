extends Node

signal OnMainAudioFinished

enum EndingType {
	NONE,
	HAPPY,
	SAD,
	NEUTRAL
}

@export var title_music: AudioStream
@export var main_music: AudioStream
@export var main_phone_call: AudioStream
@export var happy_ending: AudioStream
@export var sad_ending: AudioStream
@export var neutral_ending: AudioStream
@export var crossfade_duration: float = 2.0

@onready var main_music_player: AudioStreamPlayer = $MainMusicPlayer
@onready var phone_call_player: AudioStreamPlayer = $PhoneCallPlayer
@onready var happy_ending_player: AudioStreamPlayer = $HappyEndingPlayer
@onready var sad_ending_player: AudioStreamPlayer = $SadEndingPlayer
@onready var neutral_ending_player: AudioStreamPlayer = $NeutralEndingPlayer

var current_dominant_ending: EndingType = EndingType.NONE
var longer_track_player: AudioStreamPlayer

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if not happy_ending_player or not sad_ending_player or not neutral_ending_player:
		return
	
	happy_ending_player.stream = happy_ending
	sad_ending_player.stream = sad_ending
	neutral_ending_player.stream = neutral_ending
	
	var main_music_length: float = 0.0
	var phone_call_length: float = 0.0
	
	if main_music:
		main_music_length = main_music.get_length()
	if main_phone_call:
		phone_call_length = main_phone_call.get_length()
	
	if main_music_length >= phone_call_length:
		longer_track_player = main_music_player
	else:
		longer_track_player = phone_call_player
	
	if longer_track_player:
		longer_track_player.finished.connect(_on_longer_track_finished)
	
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
	if AppStateManager.currentState == AppStateManager.States.MENU or AppStateManager.currentState == AppStateManager.States.INTRO:
		_play_title_music()

func _on_game_state_changed() -> void:
	match AppStateManager.currentState:
		AppStateManager.States.MENU, AppStateManager.States.INTRO:
			_play_title_music()
		AppStateManager.States.GAME:
			_play_game_audio()
		AppStateManager.States.GAMEOVER:
			_stop_game_audio()
		AppStateManager.States.ENDSCREEN:
			_stop_game_audio()
			_start_ending_music()

func _play_title_music() -> void:
	_stop_all_audio()
	if title_music and main_music_player:
		main_music_player.stream = title_music
		main_music_player.play()

func _play_game_audio() -> void:
	_stop_all_audio()
	if main_music and main_music_player:
		main_music_player.stream = main_music
		main_music_player.play()
	if main_phone_call and phone_call_player:
		phone_call_player.stream = main_phone_call
		phone_call_player.play()

func _stop_game_audio() -> void:
	if main_music_player:
		main_music_player.stop()
	if phone_call_player:
		phone_call_player.stop()

func _stop_all_audio() -> void:
	_stop_game_audio()
	if happy_ending_player:
		happy_ending_player.stop()
	if sad_ending_player:
		sad_ending_player.stop()
	if neutral_ending_player:
		neutral_ending_player.stop()

func _start_ending_music() -> void:
	if happy_ending_player and happy_ending:
		happy_ending_player.play()
	if sad_ending_player and sad_ending:
		sad_ending_player.play()
	if neutral_ending_player and neutral_ending:
		neutral_ending_player.play()

func _on_longer_track_finished() -> void:
	OnMainAudioFinished.emit()

func update_ending_music(happy_score: float, sad_score: float, neutral_score: float) -> void:
	var scores = {
		EndingType.HAPPY: happy_score,
		EndingType.SAD: sad_score,
		EndingType.NEUTRAL: neutral_score
	}
	
	var new_dominant: EndingType = EndingType.NONE
	var max_score = -INF
	
	for ending_type in scores:
		if scores[ending_type] > max_score:
			max_score = scores[ending_type]
			new_dominant = ending_type
	
	if new_dominant == current_dominant_ending:
		return
	
	var old_dominant = current_dominant_ending
	current_dominant_ending = new_dominant
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if old_dominant != EndingType.NONE:
		var old_player = _get_ending_player(old_dominant)
		if old_player:
			tween.tween_property(old_player, "volume_db", -80.0, crossfade_duration)
	
	var new_player = _get_ending_player(new_dominant)
	if new_player:
		tween.tween_property(new_player, "volume_db", 0.0, crossfade_duration)

func _get_ending_player(ending_type: EndingType) -> AudioStreamPlayer:
	match ending_type:
		EndingType.HAPPY:
			return happy_ending_player
		EndingType.SAD:
			return sad_ending_player
		EndingType.NEUTRAL:
			return neutral_ending_player
		_:
			return null
