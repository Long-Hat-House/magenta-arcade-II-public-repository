extends Node

var level:int = 0;

@export var sfx:WwiseEvent;
@export var parameter:WwiseRTPC;

func _on_player_hold_potencial_change(potencial: int) -> void:
	parameter.set_value(get_parent(), potencial);
	if potencial > level:
		sfx.post(get_parent());
	level = potencial;
