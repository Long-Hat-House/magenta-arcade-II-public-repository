extends AI_WalkAndDo

@onready var graphic:Graphic_Jacare = %Graphic
@onready var body:CharacterBody3D = %Body
@onready var screen_attack_preview: ScreenAttackPreview = $Body/ScreenAttackPreview

@export var projectile:PackedScene;
@export var vfx_die:PackedScene;
@export var vfx_before_shoot:PackedScene;
@export var shoot_time:float = 2.0;
@export var use_token:String = "";
@export var token_amount:int = 0;
@export var shoot_damage_tolerance:float = 1;
@export var time_pre:float = 1.0;

@export var leftover_enemy_only_if_in_screen:VisibleOnScreenNotifier3D;
@export var leftover_enemy_scene:PackedScene;
@export var leftover_enemy_amount:int;
var leftover_count:int;
@export var left_over_enemy_first_delay:float = 2;
@export var left_over_enemy_delay:float = 1;
@export var leftover_enemy_identity_basis:bool = true;

@export var angle_turn_direction:float = 30;

static var someone_is_shooting:int;
var shooting_marked:bool;

var damage_during_shoot:int;
var shoot_tween:Tween;


enum ShootDirection{
	Left,
	Right,
}

signal tried_shooting;
signal created_leftover_enemy(instance:Node3D, index:int);

func get_direction(pos:Vector3, front:Vector3, camera_pos:Vector3)->ShootDirection:
	var camera_distance := camera_pos - pos;

	#print("DOT PRODUCT FROM %s and %s is %s" % [
		#camera_distance.normalized(),
		#front.normalized(),
		#camera_distance.normalized().dot(front.normalized())
	#]);
	if camera_distance.normalized().signed_angle_to(front.normalized(), Vector3.UP) > 0:
		return ShootDirection.Left;
	else:
		return ShootDirection.Right;

func lamp_tween()->Tween:
	var lamp:Tween = create_tween();
	lamp.tween_method(lamp_progress, 0.0, 1.0, shoot_time)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR);
	shoot_tween = lamp;
	return lamp;

func lamp_progress(value:float):
	graphic.set_lamp_progress(value);
	screen_attack_preview.set_closed(value);

func should_interrupt()->bool:
	return health.get_max_amount() - health.get_health() >= shoot_damage_tolerance;

func shoot(dir:ShootDirection):
	damage_during_shoot = 0;
	graphic.set_side(true if dir == ShootDirection.Right else false);
	graphic.set_attacking(true);
	if should_interrupt():
		interrupt_shoot();
		return;
	await lamp_tween().finished;
	if set_marked_shooting(true):
		if vfx_before_shoot:
			var vfx_intro:Node3D = InstantiateUtils.InstantiateInTree(vfx_before_shoot, body);
			await vfx_intro.tree_exiting;
		await get_tree().physics_frame;
		InstantiateUtils.InstantiateInTree(projectile, graphic.get_instantiate_place(dir == ShootDirection.Right), Vector3.ZERO, false, false);
	graphic.set_attacking(false);
	set_marked_shooting(false);
	tried_shooting.emit();

func _exit_tree() -> void:
	set_marked_shooting(false);

func set_marked_shooting(shooting:bool)->bool:
	if shooting != shooting_marked:
		if shooting and someone_is_shooting > 0:
			return false;
		shooting_marked = shooting;
		if shooting:
			someone_is_shooting += 1;
		else:
			someone_is_shooting -= 1;
		return true;
	return false;

func is_shooting()->bool:
	return shoot_tween and shoot_tween.is_running();

func interrupt_shoot():
	graphic.set_interrupt();
	graphic.set_attacking(false);
	tried_shooting.emit();
	screen_attack_preview.interrupt();
	if shoot_tween and shoot_tween.is_running():
		shoot_tween.kill();
	lamp_progress(0);


func run_anim(pre:StringName, pos:StringName):
	graphic.anim.play(pre);
	await graphic.anim.animation_finished;
	graphic.anim.play(pos);


func ai_before_walk():
	graphic.set_walk(true);
	graphic.wheel.speed_scale = 1;

func ai_after_walk():
	if not use_token.is_empty():
		await Tokenizer.await_next_token_and_pick(use_token, self, token_amount);
	await get_tree().create_timer(time_pre).timeout;
	graphic.set_walk(false);
	graphic.wheel.speed_scale = 0;
	var direction:ShootDirection = get_direction(body.global_position, -body.global_basis.z, LevelCameraController.main_camera.global_position);
	shoot(direction);
	await tried_shooting;
	if not use_token.is_empty():
		await Tokenizer.free_token(use_token, self);
	await get_tree().create_timer(left_over_enemy_first_delay).timeout;
	var instantiate_place := graphic.get_instantiate_place(direction == ShootDirection.Right)
	while leftover_count < leftover_enemy_amount:
		spawn_leftover_enemy(instantiate_place, leftover_count);
		await get_tree().create_timer(left_over_enemy_delay).timeout;
		leftover_count += 1;
	for i in 4:
		await get_tree().create_timer(left_over_enemy_delay).timeout;
	destroy();
	vanish();


func ai_physics_process(delta:float):
	ai_physics_walk_and_do(body, delta);


func vanish():
	queue_free();

func destroy():
	if vfx_die:
		InstantiateUtils.InstantiateInTree(vfx_die, body);


func _on_health_dead(health: Health) -> void:
	destroy();
	#if leftover_enemy_scene:
		#for index:int in range(leftover_enemy_amount):
			#spawn_leftover_enemy(body, index);
	vanish();
var spawn_tween:Tween;


func spawn_leftover_enemy(where:Node3D, index:int):
	if leftover_enemy_only_if_in_screen:
		if not leftover_enemy_only_if_in_screen.is_on_screen(): return;
	
	var inst:Node3D = InstantiateUtils.Instantiate(leftover_enemy_scene, get_parent(), false);
	inst.global_transform = where.global_transform;
	if leftover_enemy_identity_basis:
		inst.global_basis = Basis.IDENTITY;
	created_leftover_enemy.emit(inst, index);

	if spawn_tween and spawn_tween.is_valid():
		spawn_tween.kill();
	spawn_tween = create_tween();
	graphic.scale = Vector3(randf_range(0.15, 0.9), randf_range(1.5, 4), randf_range(0.5, 1.0)).normalized() * 2.5;
	spawn_tween.tween_property(graphic, "scale", Vector3.ONE, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	vanish();


func _on_health_hit(damage: Health.DamageData, health: Health) -> void:
	if is_shooting() and should_interrupt():
		interrupt_shoot();
