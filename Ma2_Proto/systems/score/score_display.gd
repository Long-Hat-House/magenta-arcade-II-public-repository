class_name ScoreDisplay extends Control

@export var _score_letter_scene:PackedScene
@export var _score_letters_container:Control

var _letters:Array[ScoreDisplayLetter]

func _ready() -> void:
	for obj in _score_letters_container.get_children():
		if obj is ScoreDisplayLetter:
			_letters.append(obj)

func set_text(text:String):
	while _letters.size() < text.length():
		var l = _score_letter_scene.instantiate()
		_score_letters_container.add_child(l)
		_letters.append(l)

	var i = 0
	var leading_zeroes:bool = true
	var animate:bool = false
	var delay:float = 0.01
	var intensity:float = 0
	for c in text:
		if leading_zeroes && c != "0":
			leading_zeroes = false
		if animate:
			delay += 0.1
		if c != _letters[i].letter_set():
			animate = true
		intensity = max(float(c)/9.0, intensity)
		_letters[i].set_letter(i, c, intensity, animate, delay, leading_zeroes)
		i+=1
