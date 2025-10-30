class_name ScoreShow extends Control

@export var _anim:AnimationPlayer
@export var _label:Label

@export var _min_score_size:int = 5
@export var _max_score_size:int = 300
@export var _to_set_size:Control
@export var _size_per_score:Curve

var _info:ScoreInfo
var _position:Vector3

func _process(delta: float) -> void:
	if _info.world_positioned && LevelCameraController.instance:
		global_position = LevelCameraController.instance.world_to_screen_position(_position)

func set_score(change_value:int, info:ScoreInfo, giver:ScoreGiver):
	if _anim.is_playing():
		return

	_info = info

	if ScoreManager.instance.get_current_boost_multiplier() <= 1:
		_label.modulate = ScoreManager.COLOR_NO_COMBO
	elif ScoreManager.instance.is_in_max_boost():
		_label.modulate = ScoreManager.COLOR_MAX_COMBO
		z_index = 3
	else:
		_label.modulate = ScoreManager.COLOR_COMBO
		z_index = 2

	_to_set_size.scale = Vector2.ONE * _size_per_score.sample(inverse_lerp(_min_score_size,_max_score_size,change_value))

	_anim.play("show")
	_anim.animation_finished.connect(_on_animation_finished)
	_label.text = str(change_value)
	_position = giver.get_score_position()

	if _info.world_positioned:
		global_position = LevelCameraController.instance.world_to_screen_position(_position)

func _on_animation_finished(anim_name: StringName):
	queue_free()
