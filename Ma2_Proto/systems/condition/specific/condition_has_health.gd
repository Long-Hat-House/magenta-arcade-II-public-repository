class_name Condition_HasHealth extends Condition

@export var more_than:int = 1;

func is_condition()-> bool:
	var player := Player.instance;
	if player:
		return player.hp > more_than;
	return false;
