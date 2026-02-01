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

@export var baby_happy_sfx: AudioStream
@export var baby_sad_sfx: AudioStream
@export var wife_happy_sfx: AudioStream
@export var wife_sad_sfx: AudioStream
@export var son_happy_sfx: AudioStream
@export var son_sad_sfx: AudioStream

@onready var main_music_player: AudioStreamPlayer = $MainMusicPlayer
@onready var title_music_player: AudioStreamPlayer = $TitleMusicPlayer
@onready var phone_call_player: AudioStreamPlayer = $PhoneCallPlayer
@onready var happy_ending_player: AudioStreamPlayer = $HappyEndingPlayer
@onready var sad_ending_player: AudioStreamPlayer = $SadEndingPlayer
@onready var neutral_ending_player: AudioStreamPlayer = $NeutralEndingPlayer
@onready var baby_happy_player: AudioStreamPlayer = $BabyHappyPlayer
@onready var baby_sad_player: AudioStreamPlayer = $BabySadPlayer
@onready var wife_happy_player: AudioStreamPlayer = $WifeHappyPlayer
@onready var wife_sad_player: AudioStreamPlayer = $WifeSadPlayer
@onready var son_happy_player: AudioStreamPlayer = $SonHappyPlayer
@onready var son_sad_player: AudioStreamPlayer = $SonSadPlayer

var current_dominant_ending: EndingType = EndingType.NONE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if not happy_ending_player or not sad_ending_player or not neutral_ending_player:
		return
	
	title_music_player.stream = title_music
	happy_ending_player.stream = happy_ending
	sad_ending_player.stream = sad_ending
	neutral_ending_player.stream = neutral_ending
	
	if baby_happy_player and baby_happy_sfx:
		baby_happy_player.stream = baby_happy_sfx
	if baby_sad_player and baby_sad_sfx:
		baby_sad_player.stream = baby_sad_sfx
	if wife_happy_player and wife_happy_sfx:
		wife_happy_player.stream = wife_happy_sfx
	if wife_sad_player and wife_sad_sfx:
		wife_sad_player.stream = wife_sad_sfx
	if son_happy_player and son_happy_sfx:
		son_happy_player.stream = son_happy_sfx
	if son_sad_player and son_sad_sfx:
		son_sad_player.stream = son_sad_sfx
	
	phone_call_player.finished.connect(_on_longer_track_finished)	
	AppStateManager.OnGameStateChanged.connect(_on_game_state_changed)
	
	if AppStateManager.currentState == AppStateManager.States.MENU:
		_play_title_music()
	elif AppStateManager.currentState == AppStateManager.States.INTRO:
		_play_game_audio()

func _on_game_state_changed() -> void:
	match AppStateManager.currentState:
		AppStateManager.States.MENU:
			_play_title_music()
		AppStateManager.States.INTRO:
			_play_game_audio()
		AppStateManager.States.GAME:
			pass
		AppStateManager.States.GAMEOVER:
			_stop_game_audio()
		AppStateManager.States.ENDSCREEN:
			_stop_game_audio()
			_start_ending_music()

func _play_title_music() -> void:
	_stop_all_audio()
	if title_music and title_music_player:
		if title_music_player.finished.is_connected(_on_title_music_finished):
			title_music_player.finished.disconnect(_on_title_music_finished)
		title_music_player.stream = title_music
		title_music_player.volume_db = 0.0
		title_music_player.finished.connect(_on_title_music_finished)
		title_music_player.play()

func _on_title_music_finished() -> void:
	if title_music_player and AppStateManager.currentState in [AppStateManager.States.MENU, AppStateManager.States.INTRO]:
		title_music_player.play()

func _play_game_audio() -> void:
	_stop_all_audio()
	if main_music and main_music_player:
		main_music_player.stream = main_music
		main_music_player.play()
	if main_phone_call and phone_call_player:
		phone_call_player.stream = main_phone_call
		phone_call_player.play()

func _stop_game_audio() -> void:
	if phone_call_player:
		phone_call_player.stop()

func _stop_all_audio() -> void:
	_stop_game_audio()
	
	if main_music_player:
		main_music_player.stop()
	if title_music_player:
		if title_music_player.finished.is_connected(_on_title_music_finished):
			title_music_player.finished.disconnect(_on_title_music_finished)
		title_music_player.stop()
	if happy_ending_player:
		happy_ending_player.stop()
	if sad_ending_player:
		sad_ending_player.stop()
	if neutral_ending_player:
		neutral_ending_player.stop()
	if baby_happy_player:
		baby_happy_player.stop()
	if baby_sad_player:
		baby_sad_player.stop()
	if wife_happy_player:
		wife_happy_player.stop()
	if wife_sad_player:
		wife_sad_player.stop()
	if son_happy_player:
		son_happy_player.stop()
	if son_sad_player:
		son_sad_player.stop()

func _start_ending_music() -> void:
	current_dominant_ending = EndingType.NONE
	if happy_ending_player and happy_ending:
		happy_ending_player.stop()
		happy_ending_player.volume_db = -80.0
		happy_ending_player.play()
	if sad_ending_player and sad_ending:
		sad_ending_player.stop()
		sad_ending_player.volume_db = -80.0
		sad_ending_player.play()
	if neutral_ending_player and neutral_ending:
		neutral_ending_player.stop()
		neutral_ending_player.volume_db = -80.0
		neutral_ending_player.play()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F and event.ctrl_pressed:
		main_music_player.stop()
		phone_call_player.stop()
		OnMainAudioFinished.emit()

func _on_longer_track_finished() -> void:
	OnMainAudioFinished.emit()

func update_ending_music(happy_score: float, sad_score: float, neutral_score: float, person_type: Person.PersonType = Person.PersonType.BABY) -> void:
	var new_dominant = _calculate_dominant_ending(happy_score, sad_score, neutral_score)
	_crossfade_to_ending(new_dominant)
	_play_character_sfx(person_type, new_dominant)

func fade_to_neutral() -> void:
	_crossfade_to_ending(EndingType.NEUTRAL)

func _calculate_dominant_ending(happy_score: float, sad_score: float, neutral_score: float) -> EndingType:
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
	
	return new_dominant

func _crossfade_to_ending(ending_type: EndingType) -> void:
	var ending_changed = ending_type != current_dominant_ending
	
	if not ending_changed:
		return
	
	var old_dominant = current_dominant_ending
	current_dominant_ending = ending_type
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	for ending in [EndingType.HAPPY, EndingType.SAD, EndingType.NEUTRAL]:
		var player = _get_ending_player(ending)
		if not player:
			continue
		
		if ending == ending_type:
			if not player.playing:
				player.play()
			tween.tween_property(player, "volume_db", 0.0, crossfade_duration)
		else:
			tween.tween_property(player, "volume_db", -80.0, crossfade_duration)

func _play_character_sfx(person_type: Person.PersonType, ending_type: EndingType) -> void:
	var sfx_player = _get_character_sfx_player(person_type, ending_type)
	if sfx_player:
		sfx_player.play()

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

func _get_character_sfx_player(person_type: Person.PersonType, ending_type: EndingType) -> AudioStreamPlayer:
	match person_type:
		Person.PersonType.BABY:
			if ending_type == EndingType.SAD:
				return baby_sad_player
			else:
				return baby_happy_player
		Person.PersonType.WIFE:
			if ending_type == EndingType.SAD:
				return wife_sad_player
			else:
				return wife_happy_player
		Person.PersonType.SON:
			if ending_type == EndingType.SAD:
				return son_sad_player
			else:
				return son_happy_player
		_:
			return null
