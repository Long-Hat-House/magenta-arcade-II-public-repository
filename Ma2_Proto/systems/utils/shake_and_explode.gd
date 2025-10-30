class_name ShakeAndExplode extends Node3D

@export var shaker:Node3DShaker;
@export var exploder:SpawnArea;
@export var duration:float = 1.0;
@export var number_of_explosions:int;
@export var queue_free_on_finish_explode:bool;

signal exploded;

func _ready() -> void:
	shaker.shake_amplitude_ratio = 0;

func explode():
	var t := get_tree().create_tween();
	t.tween_property(shaker, "shake_amplitude_ratio", 1.0, duration);
	exploder.do_spawn(number_of_explosions, duration);
	await exploder.do_spawn_finish;
	exploded.emit();
	if queue_free_on_finish_explode:
		queue_free();
