extends Node

@export var theLabel: NodePath
@export var director: Node

var sequence_started: bool = false

var person_start_positions: Dictionary = {}
var person_end_positions: Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if not director:
		director = get_node_or_null("EndScreenDirector")
	if not director:
		director = $EndScreenDirector
	
	_setup_person_positions()

func _setup_person_positions() -> void:
	var family = $Family
	if not family:
		return
	
	var wife_sprite = family.get_node_or_null("FamilyMama")
	var son_sprite = family.get_node_or_null("FamilySon")
	var baby_sprite = family.get_node_or_null("FamilyBabyNany")
	
	if wife_sprite:
		person_start_positions[Person.PersonType.WIFE] = wife_sprite.position
		person_end_positions[Person.PersonType.WIFE] = Vector2(-641.924, 1300)
	
	if son_sprite:
		person_start_positions[Person.PersonType.SON] = son_sprite.position
		person_end_positions[Person.PersonType.SON] = Vector2(-1304.134, 835.38306)
	
	if baby_sprite:
		person_start_positions[Person.PersonType.BABY] = baby_sprite.position
		person_end_positions[Person.PersonType.BABY] = Vector2(278.7823, 1206.6641)

func _start_animation() -> void:
	var anim_player = get_node_or_null("MainAnimation")
	if anim_player and anim_player is AnimationPlayer:
		anim_player.play("end_scene")

func _get_persons_in_order() -> Array[Person]:
	var family = $Family
	
	var persons_by_type: Dictionary = {}
	for child in family.find_children("*", "Person"):
		if child is Person:
			persons_by_type[child.person] = child
	
	var order = [Person.PersonType.WIFE, Person.PersonType.SON, Person.PersonType.BABY]
	var result: Array[Person] = []
	for person_type in order:
		if persons_by_type.has(person_type):
			result.append(persons_by_type[person_type])
	return result

var current_person = 0
var persons = []
var scores: Array[float] = []

func _sequence_family_scores() -> void:
	self.persons = _get_persons_in_order()
	self.scores = []
	for person in persons:
		var score = person.calculate_score()
		scores.append(score)
	AudioManager.fade_to_neutral()
	
	if director:
		if director.has_method("start_sequence"):
			director.person_sequence_started.connect(_on_person_sequence_started)
			director.start_sequence(persons, scores)

func _on_person_sequence_started(person: Person, score: float, index: int) -> void:
	var ending_type = AudioManager.EndingType.HAPPY if score > 1.0 else AudioManager.EndingType.SAD
	_trigger_person_sequence(person, score, ending_type, index)

func _trigger_person_sequence(person: Person, score: float, ending_type: AudioManager.EndingType, index: int) -> void:
	var happy_score = 1.0 if score > 1.0 else 0.0
	var sad_score = 1.0 if score <= 1.0 else 0.0
	
	var label_node = get_node(theLabel) as Label
	if label_node:
		var person_name = Person._enum_to_string[person.person]
		label_node.text = person_name + ": " + str(score)
	
	var crossfade_duration = -1.0
	if director and "music_crossfade_duration" in director:
		crossfade_duration = director.music_crossfade_duration
	
	AudioManager.update_ending_music(happy_score, sad_score, 0, person.person, crossfade_duration)
	_trigger_person_particles(person, ending_type)
	_trigger_person_movement(person)

func _trigger_person_particles(person: Person, ending_type: AudioManager.EndingType) -> void:
	if not person:
		return
	
	var tears_node = person.tears
	var hearts_node = person.hearts
	
	if ending_type == AudioManager.EndingType.SAD:
		if tears_node:
			var tears_left = tears_node.get_node_or_null("TearsLeftEye")
			var tears_right = tears_node.get_node_or_null("TearsRightEye")
			if tears_left and tears_left is GPUParticles2D:
				tears_left.emitting = true
			if tears_right and tears_right is GPUParticles2D:
				tears_right.emitting = true
		if hearts_node:
			var hearts = hearts_node.get_node_or_null("Hearts")
			if hearts and hearts is GPUParticles2D:
				hearts.emitting = false
	else:
		if hearts_node:
			var hearts = hearts_node.get_node_or_null("Hearts")
			if hearts and hearts is GPUParticles2D:
				hearts.emitting = true
		if tears_node:
			var tears_left = tears_node.get_node_or_null("TearsLeftEye")
			var tears_right = tears_node.get_node_or_null("TearsRightEye")
			if tears_left and tears_left is GPUParticles2D:
				tears_left.emitting = false
			if tears_right and tears_right is GPUParticles2D:
				tears_right.emitting = false

func _trigger_person_movement(person: Person) -> void:
	if not person:
		return
	
	var person_sprite = person.get_parent()
	if not person_sprite or not person_sprite is Node2D:
		return
	
	if not person_end_positions.has(person.person):
		return
	
	var start_pos = person_start_positions.get(person.person, person_sprite.position)
	var end_pos = person_end_positions[person.person]
	
	var movement_duration = 4.5
	if director and "person_movement_duration" in director:
		movement_duration = director.person_movement_duration
	
	person_sprite.position = start_pos
	var tween = create_tween()
	tween.tween_property(person_sprite, "position", end_pos, movement_duration)

func next_person():
	if AppStateManager.currentState != AppStateManager.States.ENDSCREEN:
		return
	
	var label_node = get_node(theLabel) as Label
	if not label_node:
		return
	
	if self.persons.size() <= current_person:
		label_node.text = "Neutral"
		AudioManager.fade_to_neutral()
		return
	
	var person_name = Person._enum_to_string[persons[current_person].person]
	var score = scores[current_person]
	
	var happy_score = 0.0
	var sad_score = 0.0
	
	if score > 1.0:
		happy_score = 1.0
	else:
		sad_score = 1.0
	
	label_node.text = person_name + ": " + str(score)
	AudioManager.update_ending_music(happy_score, sad_score, 0, persons[current_person].person)
	current_person += 1
