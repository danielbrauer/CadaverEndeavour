extends Node

@export var delay_until_first_person: float = 11.6
@export var time_per_person: float = 5.4
@export var sfx_duration: float = 2.0
@export var music_crossfade_duration: float = 0.5
@export var person_movement_duration: float = 4.5

signal person_sequence_started(person: Person, score: float, index: int)
signal sequence_completed

var persons: Array[Person] = []
var scores: Array[float] = []
var current_index: int = -1
var is_running: bool = false

func start_sequence(persons_array: Array[Person], scores_array: Array[float]) -> void:
	if is_running:
		return
	
	persons = persons_array
	scores = scores_array
	current_index = -1
	is_running = true
	
	await _wait_for_delay()
	_process_next_person()

func _wait_for_delay() -> void:
	await get_tree().create_timer(delay_until_first_person).timeout

func _process_next_person() -> void:
	if not is_running:
		return
	
	current_index += 1
	
	if current_index >= persons.size():
		_process_neutral()
		return
	
	var person = persons[current_index]
	var score = scores[current_index]
	
	person_sequence_started.emit(person, score, current_index)
	
	await get_tree().create_timer(time_per_person).timeout
	
	_process_next_person()

func _process_neutral() -> void:
	is_running = false
	sequence_completed.emit()

func stop_sequence() -> void:
	is_running = false
	current_index = -1
