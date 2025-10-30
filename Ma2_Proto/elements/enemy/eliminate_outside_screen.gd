extends Node

@export var time_to_check:float = 2;
@export var time_without_process:float = 20;

@export var base:Node;

var processed_already:bool;

func _ready():
	if base == null:
		if owner != null:
			base = owner;
		elif get_parent() != null:
			base = get_parent();

func _process(delta: float) -> void:
	if time_to_check > 0:
		time_to_check -= delta;
		return;
		
	if base.can_process():
		processed_already = true;
	elif processed_already:
		time_without_process -= delta;
		if time_without_process < 0:
			base.queue_free();
