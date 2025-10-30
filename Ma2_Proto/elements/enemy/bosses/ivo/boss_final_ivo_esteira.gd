extends Node3D

@onready var enemies_parent:Node3D = $enemies_center/enemies_parent;
@onready var belt: Element_Belt = $belt

var going_right:bool = true;

@export var sfx_machine_walk: AkEvent3D;

@export var distance_walk:float = 8;

var right_occupied:bool = false;
var left_occupied:bool = false;

signal enemy_created(enemy:Node3D);

func _ready() -> void:
	belt.set_animation_off();
	old_pos = enemies_parent.position;
	
var old_pos:Vector3;
func _process(delta: float) -> void:
	var pos := enemies_parent.position;
	belt.walk(pos - old_pos);
	old_pos = pos;
	
	if Input.is_action_just_pressed("ui_right"):
		go(true);
	elif Input.is_action_just_pressed("ui_left"):
		go(false);
	if Input.is_action_just_pressed("ui_accept"):
		add_enemy(preload("res://elements/enemy/pizza/enemy_pizza_roboto_shooter.tscn").instantiate());

var directions_arr:Array[int] = [
	2,
	2,
	2,
	2,
	-2,
	-2,
	-2,
	-2,
	1,
	1,
	-1,
	-1,
]
var directions_now:Array[int] = []

## go through the shuffled array (so all the moves will always happen in some order), in a way that two equal moves are more likely
func get_direction()->bool:
	if directions_now.is_empty():
		directions_now = directions_arr.duplicate(false);
		directions_now.shuffle();
	if directions_now[0] == 0:
		directions_now.pop_front();
		if directions_now.is_empty():
			directions_now = directions_arr.duplicate(false);
			directions_now.shuffle();
	if directions_now[0] > 0:
		directions_now[0] -= 1;
		return false;
	else:
		directions_now[0] += 1;
		return true;
	return randf() < 0.5;

func add_enemy(enemy:Node3D):
	var walker = enemy as AI_WalkAndDo;
	if walker:
		walker.distanceMax = 0;
	enemies_parent.add_child(enemy);
	
	var right:bool = get_direction();
	
	enemy.position = get_free_slot(right) - enemies_parent.position;
	enemy_created.emit(enemy);
	go(!right);
	
func get_free_slot(right:bool)->Vector3:
	return (Vector3.RIGHT if right else Vector3.LEFT) * distance_walk * 1.5;
	
func go(right:bool):
	var t:= create_tween();
	t.tween_callback(sfx_machine_walk.post_event);
	t.tween_property(enemies_parent, 
			"position", 
			Vector3.RIGHT * (distance_walk if right else -distance_walk), 
			1.5
			).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING);
	await t.finished;
	
	## Eliminate free enemy in the _right_ place.
	if right:
		for child:Node3D in enemies_parent.get_children():
			var dist:float = child.global_position.x - LevelCameraController.main_camera.global_position.x;
			if dist > distance_walk:
				child.queue_free();
	else:
		for child:Node3D in enemies_parent.get_children():
			var dist:float = child.global_position.x - LevelCameraController.main_camera.global_position.x;
			if dist < -distance_walk:
				child.queue_free();

func decouple_object(node:Node3D):
	if node != null and node.owner != null:
		node = node.owner;
	if is_instance_valid(node):
		node.reparent(InstantiateUtils.get_topmost_instantiate_node());
		var node3D := node as Node3D;
		if node3D:
			node3D.global_position.y = 0;

var bodies_time:Dictionary[Node3D, int] = {}

func check_time(node:Node3D)->bool:
	if bodies_time.has(node):
		return (float(Time.get_ticks_msec() - bodies_time[node]) * 0.001) > 0.1;
	return false; 

func _on_leave_area_body_entered(body: Node3D) -> void:
	bodies_time[body] = Time.get_ticks_msec();
	
func _on_leave_area_body_exited(body: Node3D) -> void:
	if check_time(body):
		decouple_object(body);
	bodies_time.erase(body);


func _on_leave_area_area_entered(area: Area3D) -> void:
	bodies_time[area] = Time.get_ticks_msec();
	
func _on_leave_area_area_exited(area: Area3D) -> void:
	if check_time(area):
		decouple_object(area);
	bodies_time.erase(area);
