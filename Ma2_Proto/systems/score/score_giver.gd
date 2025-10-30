class_name ScoreGiver extends Node

@export var info:ScoreInfo
@export var health:Health
@export var point_position:Node3D

signal score_given(giver:ScoreGiver)
signal score_missed(giver:ScoreGiver)

var _score_given:bool = false

func _ready():
	if health:
		health.dead_damage.connect(_on_exported_health_dead);

func _enter_tree() -> void:
	_score_given = false

func _exit_tree() -> void:
	if !_score_given && ScoreManager.instance:
		ScoreManager.instance.miss_score(info, self)
		score_missed.emit(self)

func _on_exported_health_dead(damage:Health.DamageData, h:Health):
	if damage and damage.scores:
		give_score();

#public function!
func give_score():
	if _score_given:
		push_error("[SCORE GIVER] %s Giving score that already gave!" % [owner.name])
		return
	ScoreManager.instance.gain_score(info, self)
	_score_given = true
	score_given.emit(self)

func get_score_position() -> Vector3:
	if point_position == null:
		var parent = get_parent();
		while parent and not (parent is Node3D):
			parent = parent.get_parent();
		var parent3D:Node3D = parent as Node3D;
		point_position = parent3D;

	if point_position:
		return point_position.global_position
	else:
		return Vector3.ZERO
