class_name UnpositionedScoreShow extends Control

@export var _anim:AnimationPlayer
@export var _label_title:Label
@export var _label_score:Label

func set_score(change_value:int, info:ScoreInfo, giver:ScoreGiver):
	if _anim.is_playing():
		return

	if _label_title:
		_label_title.text = info.score_title
	if _label_score:
		_label_score.text = str(change_value)

	modulate = MA2Colors.MAGENTA if change_value < 0 else Color.WHITE

	_anim.play("show")
	_anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName):
	queue_free()
