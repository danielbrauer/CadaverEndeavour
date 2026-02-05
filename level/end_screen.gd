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
	if AppStateManager.currentState == AppStateManager.States.ENDSCREEN:
		modulate = Color.WHITE
		var anim_player = $MainAnimation as AnimationPlayer
		if anim_player:
			anim_player.play("RESET")
			anim_player.advance(0.0)
			anim_player.play("end_scene")
		if not sequence_started:
			sequence_started = true
			_sequence_family_scores()
		AudioManager.fade_to_neutral()

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
		if score > 1.0:
			if person.hearts:
				person.hearts.visible = true
			if person.tears:
				person.tears.visible = false
		else:
			if person.tears:
				person.tears.visible = true
			if person.hearts:
				person.hearts.visible = false
	AudioManager.fade_to_neutral()

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
		if persons[current_person].hearts:
			persons[current_person].hearts.visible = true
		if persons[current_person].tears:
			persons[current_person].tears.visible = false
	else:
		sad_score = 1.0
		if persons[current_person].tears:
			persons[current_person].tears.visible = true
		if persons[current_person].hearts:
			persons[current_person].hearts.visible = false
	
	label_node.text = person_name + ": " + str(score)
	AudioManager.update_ending_music(happy_score, sad_score, 0, persons[current_person].person)
	current_person += 1
