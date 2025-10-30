extends StaticBody3D

@onready var health1: Health = $"Alive Health"
@onready var health2: Health = $"Dead Health"
@onready var snake_body: Graphic_SnakeBody = $snakeBody

@onready var enemy_marker: Node3D = $"Enemy Marker"

var index:int;
var total_bodies:int;

@export var explosion_vfx:PackedScene;

@export var time_outside_screen:float = 1.0;
@export var notifier:VisibleOnScreenNotifier3D;
var count_outside_screen:float;
var entered:bool;


signal died_once;
signal died_second;
signal vanished;

func _on_health_dead_parameterless() -> void:
	explode();

	snake_body.set_broken(true);

	enemy_marker.queue_free();
	died_once.emit();
	
	
func _on_dead_health_dead_parameterless() -> void:
	explode();
	died_second.emit();
	vanish();


func explode():
	if explosion_vfx:
		InstantiateUtils.InstantiateInTree(explosion_vfx, self);

func kill():
	health1.damage_kill(self);
	await get_tree().create_timer(0.5).timeout;
	health2.damage_kill(self);

func _process(delta: float) -> void:
	if entered and not notifier.is_on_screen():
		count_outside_screen += delta;
		if count_outside_screen > time_outside_screen:
			vanish();


func vanish():
	vanished.emit();
	queue_free.call_deferred();


func _on_left_screen()->void:
	pass;


func _on_entered_screen() -> void:
	entered = true;
