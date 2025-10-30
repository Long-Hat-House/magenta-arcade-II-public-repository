extends Node

@export var _score_display:ScoreDisplay

@export_category("World Positioned Score")
@export var _score_show_scene:PackedScene
@export var _score_show_container:Control

@export_category("Unpositioned Score")
@export var _unpositioned_score_show_scene:PackedScene
@export var _unpositioned_score_show_container:Control

@export_category("Combo Score")
@export var _score_combo_show_scene:PackedScene
@export var _score_combo_show_container:Control

@export_category("Score Boost")
@export var _score_boost_progress:ProgressBarFloatMultiple
@export var _max_boost_animation:Switch_Oning_Offing_AnimationPlayer
@export var _overtime_animation:Switch_Oning_Offing_AnimationPlayer

var _boost_bar_count = 0

func _ready() -> void:
	while !ScoreManager.instance:
		await get_tree().process_frame

	ScoreManager.instance.score_updated.connect(_on_score_updated)
	ScoreManager.instance.score_gained.connect(_on_score_gained)
	ScoreManager.instance.combo_started.connect(_on_combo_started)
	ScoreManager.instance.boost_updated.connect(_on_boost_updated)
	ScoreManager.instance.entered_overtime.connect(_on_entered_overtime)

	await get_tree().process_frame
	_on_score_updated(0,0)
	_score_boost_progress.set_data(3, _boost_bar_count)

func _on_entered_overtime():
	_overtime_animation.set_switch(true)

func _on_boost_updated():
	_max_boost_animation.set_switch(ScoreManager.instance.is_in_max_boost())
	var new_count:int = ceilf(ScoreManager.instance.get_current_boost())
	if new_count != _boost_bar_count:
		_boost_bar_count = new_count
		_score_boost_progress.set_data(3, _boost_bar_count)
	_score_boost_progress.set_fill(ScoreManager.instance.get_current_boost())

func _on_score_updated(change_value:int, current_value:int):
	_score_display.set_text(ScoreManager.instance.get_current_score_text())

func _on_score_gained(change_value:int, info:ScoreInfo, giver:ScoreGiver):
	if is_instance_valid(giver) && info.world_positioned:
		var ss = _score_show_scene.instantiate() as ScoreShow
		ss.set_score(change_value, info, giver)
		_score_show_container.add_child(ss)
	else:
		var ss = _unpositioned_score_show_scene.instantiate() as UnpositionedScoreShow
		ss.set_score(change_value, info, giver)
		_unpositioned_score_show_container.add_child(ss)


func _on_combo_started(bucket_score:int, starting_count:int, info:ScoreInfo, giver:ScoreGiver):
	var cs = _score_combo_show_scene.instantiate() as ScoreComboShow
	_score_combo_show_container.add_child(cs)
	cs.start_combo(info)
	cs.on_combo_updated(bucket_score, starting_count, info, giver)
