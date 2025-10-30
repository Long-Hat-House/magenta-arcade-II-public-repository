class_name ScoreComboShow extends Control

@export var _anim:AnimationPlayer
@export var _label_count:Label
@export var _label_points:Label
@export var _label_title:Label
@export var _label_bucket:Label
@export var _timer_bar:ProgressBar
@export var _combo_scale:Control
@export var _combo_timer_curve:Curve
@export var _post_text_label:Label
@export var _enemy_count_indexed_bar:ProgressBarIndexed

@export_category("Audio")
@export var _sfx_combo_updated_rtpc:WwiseRTPC
@export var _sfx_combo_updated:WwiseEvent
@export var _sfx_combo_points:WwiseEvent
@export var _sfx_combo_text:WwiseEvent

var _finished:bool = false

func start_combo(info:ScoreInfo):

	ScoreManager.instance.combo_updated.connect(on_combo_updated)
	ScoreManager.instance.combo_finished.connect(on_combo_finished)

	visible = false
	if _label_count:
		_label_count.modulate = ScoreManager.COLOR_NO_COMBO
		_label_count.text = "?"
	if _label_title:
		_label_title.text = ""
	if _timer_bar:
		_timer_bar.set_value_no_signal(0)

	_anim.animation_finished.connect(_on_animation_finished)
	_anim.play(&"in")

	if _enemy_count_indexed_bar:
		_enemy_count_indexed_bar.set_values(info.combo_max_count, 1, true)

func _on_animation_finished(anim_name: StringName):
	if anim_name == &"out":
		queue_free()

func _process(delta: float) -> void:
	if _finished:
		return

	if ScoreManager.instance:
		var eval:float = _timer_ratio_evaluate(ScoreManager.instance.get_current_combo_time_ratio())
		if _timer_bar:
			_timer_bar.value = eval
		if _combo_scale:
			_combo_scale.scale.x = eval

func _timer_ratio_evaluate(ratio) -> float:
	return _combo_timer_curve.sample(ratio)

func on_combo_updated(bucket:int, count:int, info:ScoreInfo, giver:ScoreGiver):
	if _finished:
		return

	if count > 0:
		visible = true
		_anim.play(&"in")
	else:
		visible = false
		return

	if _label_count:
		_label_count.modulate = ScoreManager.COLOR_COMBO
		_label_count.text = str(count)

	if _label_points:
		_label_points.text = str(bucket)

	if _label_bucket:
		_label_bucket.text = str(bucket)

	if _label_title:
		_label_title.text = ""#info.score_title

	if _enemy_count_indexed_bar:
		_enemy_count_indexed_bar.set_values(info.combo_max_count, count, false)

	if _sfx_combo_updated_rtpc: _sfx_combo_updated_rtpc.set_global_value(count)
	if _sfx_combo_updated_rtpc: _sfx_combo_updated_rtpc.set_value(self, count)
	if _sfx_combo_updated: _sfx_combo_updated.post(self)

func on_combo_finished(bucket:int, count:int, info:ScoreInfo, giver:ScoreGiver, mode:ScoreManager.ComboFinishMode):
	if _finished:
		return
	_finished = true

	if count > 0:
		visible = true
	else:
		visible = false
		queue_free()
		return

	if _sfx_combo_updated_rtpc: _sfx_combo_updated_rtpc.set_global_value(0)
	if _sfx_combo_updated_rtpc: _sfx_combo_updated_rtpc.set_value(self, count)
	if _sfx_combo_points: _sfx_combo_points.post(self)

	match mode:
		ScoreManager.ComboFinishMode.Timeout:
			if count <= 3:
				_post_text_label.text = "hud_score_combo_1"
			if count <= 5:
				_post_text_label.text = "hud_score_combo_2"
			elif count <= 7:
				_post_text_label.text = "hud_score_combo_3"
			elif count <= 8:
				_post_text_label.text = "hud_score_combo_4"
			elif count <= 9:
				_post_text_label.text = "hud_score_combo_5"
			_combo_scale.scale.x = 0
		ScoreManager.ComboFinishMode.Max:
			_post_text_label.text = "hud_score_combo_max"
			_combo_scale.scale.x = 1
			_label_points.modulate = ScoreManager.COLOR_MAX_COMBO
		ScoreManager.ComboFinishMode.Swap:
			_post_text_label.text = "Enemy Swap!"
			_combo_scale.scale.x = 1
		ScoreManager.ComboFinishMode.Hurt:
			_post_text_label.text = "Combo!" if count != 1 else ""
			_combo_scale.scale.x = 1
		ScoreManager.ComboFinishMode.Other:
			_post_text_label.text = "Combo!" if count != 1 else ""
			_combo_scale.scale.x = 1

	if _label_count:
		if count == ScoreManager.MAX_COMBO_COUNT:
			_label_count.modulate = ScoreManager.COLOR_MAX_COMBO
		_post_text_label.modulate = _label_count.modulate
		_label_count.text = str(count)


	if _label_points:
		_label_points.text = str(bucket)

	if _enemy_count_indexed_bar:
		_enemy_count_indexed_bar.set_values(ScoreManager.MAX_COMBO_COUNT, count, false)

	_anim.play(&"out")

func showing_combo_text():
	if _sfx_combo_text: _sfx_combo_text.post(self)
