class_name AI_Snake extends CharacterBody3D

const SnakeMovement = preload("res://elements/enemy/snake/snake_movement.gd")
const SnakeBody = preload("res://elements/enemy/snake/ai_enemy_snake_body.gd")

@onready var snake_movement:SnakeMovement = $SnakeMovement
@onready var bodies_container: Node3D = $BodiesContainer
@onready var graphic: Node3D = $Graphic
@onready var shape: CollisionShape3D = $CollisionShape3D
@onready var health: Health = $Health

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D


@export var height:float = 1;
@export var forward_velocity:float = 8;
@export var forward_velocity_multiplier_add_when_all_dead:float = 1.5;
@export var forward_velocity_multiplier_when_head_outside_screen:float = 2;
@export var curve_forward_velocity_gain:Curve;
@export var amplitude:float = 4;
@export var frequency:float = 1;
@export var extra_hp_per_body:float;
@export var damage_per_body_kill:float;
var original_max_hp:int;

@export var explode_vfx:PackedScene;

var added_vel_escape:float;
var added_vel_entry:float;
@export var entry_duration:float = 4;
@export var entry_duration_per_body:float = 0.25;
@export var entry_velocity_multiplier:float = 0.5;

@export var bodies_scenes:Array[PackedScene];
@export var bodies:Array[int] = []
var bodies_count:int = 0;

var starting:bool;
var dying:bool;

class Instance:
	var instance:Node3D;
	var count:float;

var instances:Array[Instance];


### Set the bodies in this snake. Use [0, 0, 1, 2], will make a snake with two wall bodies, one cannon e and one super cannon.
func set_bodies(arr:Array[int]):
	bodies = arr;
	for child in bodies_container.get_children():
		child.queue_free();
	instances.clear();
	bodies_count = 0;

	var i:int = 0;
	var distance:float = (snake_movement.get_snake_local_position(0.5) - snake_movement.get_snake_local_position(0)).length() * 2;
	var head_inst:Instance = Instance.new();
	head_inst.instance = self;
	head_inst.count = 0.0;
	head_inst.instance.global_position += Vector3.UP * height;
	instances.push_back(head_inst);

	var count:float = -1.45/distance; ##default head distance
	var scene_count:int = bodies.size();
	
	starting = true;

	for scene in bodies:
		var inst:Instance = Instance.new();
		inst.instance = bodies_scenes[scene].instantiate();

		bodies_count += 1;

		var snake_body = inst.instance as SnakeBody;
		if snake_body:
			snake_body.name = "Instance_%s_%s" % [scene, count];
			snake_body.index = bodies_count;
			snake_body.total_bodies = scene_count;

			snake_body.global_position += Vector3.UP * height;
			snake_body.died_once.connect(_body_died_first);
			snake_body.died_second.connect(_body_really_died.bind(bodies_count));
			snake_body.vanished.connect(_less_body_count);
		inst.count = count;
		count -= 1.0/distance; #default body distance

		bodies_container.add_child(inst.instance);
		instances.push_back(inst);
		
		## Too much to do in one frame, lets split
		#await get_tree().physics_frame;
		#if !is_instance_valid(self):
			#return;

	health.set_max_health(original_max_hp + (instances.size() - 1) * extra_hp_per_body)
	starting = false;

func _less_body_count():
	bodies_count -= 1;
	if bodies_count <= 0:
		if not notifier.is_on_screen():
			queue_free.call_deferred();
			
	check_escape_velocity();
			
var vel_tween:Tween;		
func tween_added_vel(variable:String, to:float, duration:float)->Tween:
	if vel_tween and vel_tween.is_valid():
		vel_tween.kill();
	vel_tween = create_tween();
	#vel_tween.tween_method(func(value:float):
		#print("setting %s to %s in %ss\t- (added_vel_entry: %s, added_vel_escape: %s)" % [
			#value, variable, duration, added_vel_entry, added_vel_escape
		#]);
		#self.set(variable, value);
		#, self.get(variable), to, duration)
	vel_tween.tween_property(self, variable, to, duration);
	return vel_tween;

func _body_died_first():
	health.damage(Health.DamageData.new(damage_per_body_kill, self, true, false));
	check_escape_velocity();
	
func check_escape_velocity():
	## Turbo if can't find an alive body
	var num_alive:int = 0;
	var num_total:int = 0;
	for body in instances:
		if is_instance_valid(body.instance):
			var snake_body = body.instance as SnakeBody;
			if snake_body and is_instance_valid(snake_body.health1):
				if snake_body.health1.is_alive():
					num_alive += 1;
		num_total += 1;
	var percentage_dead:float = 1.0 - float(num_alive)/num_total;
	var target_velocity:float = lerpf(0, forward_velocity_multiplier_add_when_all_dead, curve_forward_velocity_gain.sample(percentage_dead))
	if not notifier.is_on_screen():
		target_velocity += forward_velocity_multiplier_when_head_outside_screen;
	
	## Did not find an alive body
	tween_added_vel("added_vel_escape", target_velocity, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);


func _body_really_died(index:int):
	explode_from(index + 1, 0.12);

func _ready() -> void:
	original_max_hp = health.get_max_amount();

	await get_tree().physics_frame;
	snake_movement.forward_velocity = forward_velocity;
	snake_movement.amplitude = amplitude;
	snake_movement.frequency = frequency;

	snake_movement.initialize();
	
	await get_tree().physics_frame;
	if !starting:
		set_bodies(bodies);
		
	added_vel_entry = entry_velocity_multiplier;
	tween_added_vel("added_vel_entry", 0.0, entry_duration + bodies.size() * entry_duration_per_body)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);


func _physics_process(delta: float) -> void:
	if dying or starting:
		return;
	for inst in instances:
		if is_instance_valid(inst.instance):
			inst.count += delta + (delta * added_vel_entry) + (delta * added_vel_escape);
			var t_pos:Vector3 = snake_movement.get_snake_position(inst.count) + Vector3.UP * height;
			var translation:Vector3 = t_pos - inst.instance.global_position;
			translation.y = 0;
			#print("%s is going to %s + %s" % [inst.instance, inst.instance.global_position, translation]);
			if not translation.is_zero_approx():
				inst.instance.global_position += translation;
				var amount_curve:float = 0.75;
				var rot_angle:float = 0.0;
				translation = inst.instance.global_basis.z.lerp(translation, 0.9);
				if inst.instance == self:
					amount_curve = 0.1;
					rot_angle = snake_movement.direction.signed_angle_to(translation, Vector3.UP);
				inst.instance.global_basis = inst.instance.global_basis.looking_at(translation.normalized(), Vector3.UP, true)#.rotated(snake_movement.direction, rot_angle * 0.5);
				#inst.instance.global_basis = Basis.looking_at(translation.normalized().slerp(snake_movement.direction, amount_curve), Vector3.UP, true)#.rotated(snake_movement.direction, rot_angle * 0.5);


func timer(sec:float):
	await get_tree().create_timer(sec).timeout;

func explode():
	dying = true;
	InstantiateUtils.InstantiateInTree(explode_vfx, self);
	if is_instance_valid(graphic):
		graphic.queue_free();
	if is_instance_valid(shape):
		shape.queue_free();

	await explode_from(0, 0.2, 0.8);

	await timer(0.05);
	queue_free();

func explode_from(index:int, interval:float = 0.2, timer_multiply:float = 0.8):
	for i in range(index, instances.size()):
		if instances[i].instance != self:
			await timer(interval);
			if !is_instance_valid(instances[i].instance):
				continue;
			var instance_body := instances[i].instance as SnakeBody;
			if instance_body:
				instance_body.explode();
				instance_body.vanish();
		interval *= timer_multiply;
		i += 1;


func _on_health_dead_parameterless() -> void:
	#print("[SNAKE] Died! [%s]" % [Engine.get_frames_drawn()]);
	explode();


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if bodies_count <= 0:
		queue_free.call_deferred();
