extends "res://scenes/EnableOnState.gd"

@export var theLabel: NodePath

var sequence_started: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if valid_states.is_empty():
		valid_states = [AppStateManager.States.ENDSCREEN]
	super._ready()

func _on_game_state_changed() -> void:
	super._on_game_state_changed()
	if AppStateManager.currentState == AppStateManager.States.ENDSCREEN and not sequence_started:
		sequence_started = true
		_sequence_family_scores()

func _get_persons_in_order() -> Array[Person]:
	var family = $Family
	
	var persons_by_type: Dictionary = {}
	for child in family.get_children():
		if child is Person:
			persons_by_type[child.person] = child
	
	var order = [Person.PersonType.WIFE, Person.PersonType.SON, Person.PersonType.BABY]
	var result: Array[Person] = []
	for person_type in order:
		if persons_by_type.has(person_type):
			result.append(persons_by_type[person_type])
	return result

func _sequence_family_scores() -> void:
	var persons = _get_persons_in_order()
	if persons.is_empty():
		return
	
	var label_node = get_node(theLabel) as Label
	if not label_node:
		return
	
	while AppStateManager.currentState == AppStateManager.States.ENDSCREEN:
		var scores: Array[float] = []
		
		for person in persons:
			var score = person.calculate_score()
			scores.append(score)
		
		for i in range(persons.size()):
			if AppStateManager.currentState != AppStateManager.States.ENDSCREEN:
				break
			
			var person_name = Person._enum_to_string[persons[i].person]
			var score = scores[i]
			
			var happy_score = 0.0
			var sad_score = 0.0
			var neutral_score = 0.0
			
			if score > 1.0:
				happy_score = 1.0
			elif score < 0:
				sad_score = 1.0
			else:
				neutral_score = 1.0
			
			label_node.text = person_name + ": " + str(score)
			AudioManager.update_ending_music(happy_score, sad_score, neutral_score)
			await get_tree().create_timer(AudioManager.crossfade_duration).timeout
			await get_tree().create_timer(3.0).timeout
