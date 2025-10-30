class_name Projectile_Player_Extra extends Node3D

@onready var visuals: Node3D = $Visuals
@onready var damage_area: DamageArea = $DamageArea
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var animation: AnimationPlayer = $AnimationPlayer

@export var time_between_shots:float = 1.5;
@export var speed_max:float = 35;
@export var initial_speed:float = -1;
@export var speed_accel_relative:float = 600;
@export var speed_accel_absolute:float = 40;
@export var player_avoidance_force_quad:float = 10;
@export var player_avoidance_force_linear:float = 500;
@export var player_avoidance_distance:float = 1.5;
@export var speed_decay:float = 40;
var shot_count:float;
var speed:Vector3;

@export var shot:PackedScene;

var followee:Node3D;

var _curr_tween:Tween;

func _enter_tree() -> void:
	if !is_node_ready():
		await ready;
	set_on(true);

func set_on(value:bool):
	if value == is_on():
		return;
	
	if _curr_tween and _curr_tween.is_running():
		_curr_tween.kill();
	
	visuals.visible = value;
	particles.emitting = value;
	if value:
		animation.play("idle");
	else:
		animation.pause();
	damage_area.monitorable = value;
	damage_area.monitoring = value;
	
	if !value:
		get_tree().create_timer(particles.lifetime).timeout.connect(func():
			if !value:
				ObjectPool.repool(self);
			, CONNECT_ONE_SHOT)
		
func is_on()->bool:
	return visuals.visible;
	
func set_target(what:Node3D):
	followee = what;
	if followee != null:
		speed = get_followee_direction().normalized() * initial_speed;
		tree_exiting.connect(func():
			if is_instance_valid(what) and what == self.followee:
				what.queue_free();
			, CONNECT_ONE_SHOT)
	
func get_followee_direction()->Vector3:
	var dir := followee.global_position - global_position;
	return dir;
	
func _physics_process(delta: float) -> void:
	var has_followee:bool = is_instance_valid(followee);
	
	## Shooting
	if has_followee and time_between_shots > 0:
		shot_count += delta;
		while shot_count > time_between_shots:
				
			shot_count -= time_between_shots;
			shoot(maxf(fmod(-shot_count, time_between_shots), 0.0));
			
	## Movement
	var target_dist:Vector3;
	if has_followee:
		target_dist = get_followee_direction();
	else:
		target_dist = Vector3.ZERO;
	speed = speed.move_toward(target_dist.normalized() * speed_max, 
			speed_accel_relative * target_dist.length() * delta +\
			speed_accel_absolute * delta);
	speed = speed.move_toward(Vector3.ZERO, speed.length() * speed_decay * delta);
	speed = speed.limit_length(speed_max);
	
	var avoidance:Vector3 = Vector3.ZERO;
	for touch in Player.instance.currentTouches:
		var player_distance:Vector3 = touch.instance.global_position - global_position;
		player_distance.y = 0;
		var player_distance_length := player_distance.length();
		if player_distance_length < player_avoidance_distance:
			var avoid_force:float = 1.0 - inverse_lerp(0, player_avoidance_distance, player_distance_length);
			## Its quadratic!
			avoidance += -player_distance.normalized() *\
			(avoid_force * avoid_force * player_avoidance_force_quad +\
			avoid_force * player_avoidance_force_linear);
	speed += avoidance * delta;
			
	if has_followee:
		position += speed * delta + LevelCameraController.instance.last_physics_step_movement;
	else:
		position += speed * delta;

func shoot(extra_walk_delta:float):
	var proj = InstantiateUtils.InstantiateInTree(shot, self);
	var dir:Vector3 = Vector3.BACK;
	if dir != Vector3.ZERO:
		proj.basis = Basis.looking_at(-dir);
		
	if extra_walk_delta > 0:
		proj.walk(extra_walk_delta);

func _on_health_dead_parameterless() -> void:
	set_target(null);
	set_on(false);
