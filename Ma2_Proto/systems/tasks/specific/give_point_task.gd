class_name Task_GiveScore extends Task

@export var score_giver:ScoreGiver;
@export var score_info:ScoreInfo

func _start_task()->void:
	if score_giver:
		score_giver.give_score();
	if score_info && ScoreManager.instance:
		ScoreManager.instance.gain_score(score_info, null)
