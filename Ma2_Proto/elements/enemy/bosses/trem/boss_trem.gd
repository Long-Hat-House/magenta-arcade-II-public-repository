class_name Boss_Trem extends AnimatableBody3D

var follow_camera:bool = false;

const PROJ_ENEMY_BASIC = preload("res://elements/enemy/projectiles/proj_basic/proj_enemy_basic_follow_screen.tscn")
const PROJ_ENEMY_SUPER = preload("res://elements/enemy/projectiles/proj_super/proj_enemy_super_follow_screen.tscn")

@onready var boss_health: Health = $"Boss Health"

var max_camera_speed:float;

@export var face_dead_duration_min:float = 1.5;
@export var face_dead_duration_max:float = 2.5;
@export var face_destroy_damage:float = 50;
@export var face_destroy_shake:CameraShakeData;

@export var cam_distance_min:float = 12;
@export var cam_distance_max:float = 30;

@export var constant_shooting_origin:Node3D;

@export var camera_shake_curve:Curve;
@export var camera_shake_strength:float = 0.15;

@onready var death_spawn_area: SpawnArea = $DeathSpawnArea
	
@onready var cannon_center: Marker3D = %"Cannon Center"
@onready var cannon_center_left: Marker3D = %"Cannon Center Left"
@onready var cannon_center_right: Marker3D = %"Cannon Center Right"
@onready var cannon_left: Marker3D = %"Cannon Left"
@onready var cannon_left_mid: Marker3D = %"Cannon Left mid"
@onready var cannon_left_far: Marker3D = %"Cannon Left far"
@onready var cannon_right: Marker3D = %"Cannon Right"
@onready var cannon_right_mid: Marker3D = %"Cannon Right mid"
@onready var cannon_right_far: Marker3D = %"Cannon Right far"

@onready var sfx_movement_loop: AkEvent3DLoop = $BossTrain/Sounds/SFX_Movement_Loop

@onready var graphic: Boss_Trem_Graphic = $BossTrain
var face_left: Boss_Trem_Face:
	get:
		return graphic.face_left;
var face_right: Boss_Trem_Face:
	get:
		return graphic.face_right;
var face_center: Boss_Trem_Face:
	get:
		return graphic.face_center;

@onready var cannons:Array[Node3D] = [
	cannon_center,
	cannon_center_left,
	cannon_center_right,
	cannon_left,
	cannon_left_mid,
	cannon_left_far,
	cannon_right,
	cannon_right_mid,
	cannon_right_far,
]

@onready var adao: AnimatedSprite3D = $BossTrain/Adao

func get_cannon(index:int)->Node3D:
	return cannons[index % cannons.size()];

@onready var cannons_index = range(cannons.size());

func get_cannon_random(index:int)->Node3D:
	return get_cannon(cannons_index[index % cannons_index.size()])

@export var speed:float = 1.25;

var constant_shake_id:StringName = "train";

var curr_speed:float = 0;
var damage_speed:float = 0;

var count_tata:float;
var boolean_tata:bool;
var initial_tata:float;

signal destroyed_faces;
signal intro_end;
signal deaccelerate;
signal movement_tata;

var won:bool;

func _ready()->void:
	cannons_index.shuffle();
	face_center.get_health().currentAmount = 0;
	face_left.get_health().currentAmount = 0;
	face_right.get_health().currentAmount = 0;
	initial_tata = graphic.position.y;
	close_all_faces();
	set_vulnerable(false);

func _exit_tree() -> void:
	CameraShaker.remove_constant_shake(constant_shake_id);

func _process(delta:float)->void:
	var walk:Vector3 = Vector3.ZERO;
	if follow_camera:
		walk += LevelCameraController.instance.last_frame_movement;

	walk += Vector3.BACK * (curr_speed + damage_speed) * delta;
	position += walk;

	var total_velocity:float = curr_speed + damage_speed + absf(LevelCameraController.instance._speed_z);

	count_tata -= total_velocity * delta;
	while count_tata <= 0:
		graphic.position.y = initial_tata + 0.05 * (1.0 if boolean_tata else -1.0);
		graphic.position.x = randf_range(-1,1) * 0.05;
		count_tata += 0.8 if boolean_tata else 2.1;
		boolean_tata = !boolean_tata;
		movement_tata.emit();

	graphic.animation.speed_scale = inverse_lerp(0, speed + max_camera_speed, total_velocity) * 2;

	graphic.set_cannon_progress(get_cam_percentage());
	
	sfx_movement_loop.set_rtpc_value(total_velocity);

	CameraShaker.change_constant_shake(
		constant_shake_id,
		Vector3.ZERO.lerp(
			Vector3.ONE * camera_shake_strength,
			camera_shake_curve.sample(get_cam_percentage())
		)
	)
	
	if Input.is_key_pressed(KEY_K):
		boss_health.damage(Health.DamageData.new(100 * delta));

func set_vulnerable(vuln:bool):
	boss_health.invulnerable = !vuln;

func get_cam_percentage()->float:
	if boss_health.is_alive():
		var z_distance:float = (LevelCameraController.instance.get_pos_with_dynamic() - global_position).z;
		return 1.0 - clampf(inverse_lerp(cam_distance_min, cam_distance_max, z_distance), 0.0, 1.0);
	else:
		return 0.0;


func cmd_boss()->Level.CMD:
	var info = {
		curr_shot_index = 0,
	}

	var shoot_many = func shoot_many(amount:int):
		while amount > 0:
			amount -= 1;
			shoot_player(PROJ_ENEMY_BASIC, get_cannon_random(info.curr_shot_index))
			info.curr_shot_index += 1;

	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func tween_train():
			adao.set_idle();
			create_tween().tween_property(self, "curr_speed", speed, 20);
			sfx_movement_loop.start_loop();
			tween_smoke(1.0, 24.0, 0.5);
			),
		Level.CMD_Parallel.new([
			## Waits until too much on the front
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func player_instant_death_condition():
					#print("[BOSS] Cam percentage is %s [%s]" % [get_cam_percentage(), Engine.get_frames_drawn()]);
					return get_cam_percentage() >= 1;
					),
				Level.CMD_Callable.new(func kill_animation():
					graphic.cannon_strike(0.5, 0.5);
					won = true;
					),
				Level.CMD_Wait_Seconds.new(1.25),
				Level.CMD_Callable.new(func player_instant_death():
					Player.instance.kill();
					HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
					),
				Level.CMD_Wait_Forever.new(),
			]),

			## Faces
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(1),

				cmd_open_faces_and_close_them([face_left]),

				Level.CMD_Wait_Seconds.new(1),

				cmd_open_faces_and_close_them([face_right]),

				Level.CMD_Callable.new(intro_end.emit.bind()),

				Level.CMD_Wait_Seconds.new(1),

				cmd_open_faces_and_close_them([face_center]),

				Level.CMD_Sequence.new([
					Level.CMD_Wait_Seconds.new(0.65),
					cmd_open_faces_and_close_them([face_center, face_left, face_right], get_only_random_part.bind(2)),
				], 6),

				Level.CMD_Sequence.new([
					Level.CMD_Wait_Seconds.new(0.25),
					cmd_open_faces_and_close_them([face_center, face_left, face_right]),
					Level.CMD_Wait_Seconds.new(0.25),
					cmd_open_faces_and_close_them([face_center, face_left, face_right], get_only_random_part.bind(2)),
				], -1),
			]),

			## Constant Shooting
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Signal.new(intro_end),
				
				## Very easy
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return boss_health.get_health_percentage() < 0.8;
						),
					Level.CMD_Sequence.new([
						cmd_shoot_basic_line(1.2,  [1,0]),
						cmd_shoot_basic_line(1.2, [0,1,0]),
						cmd_shoot_basic_line(1.2,  [0,1]),
						cmd_shoot_basic_line(1.2, [0,1,0]),
					],-1),
				]),
				## Easy
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return boss_health.get_health_percentage() < 0.6;
						),
					Level.CMD_Sequence.new([
						cmd_shoot_basic_line(1.1,  [0,1]),
						cmd_shoot_basic_line(1.1, [1,0,1]),
						cmd_shoot_basic_line(1.1,  [1,0]),
						cmd_shoot_basic_line(1.1, [1,1,1]),
					],-1),
				]),
				
				## Normal
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return boss_health.get_health_percentage() < 0.4;
						),
					Level.CMD_Sequence.new([
						cmd_shoot_basic_line(1.0,  [1,1]),
						cmd_shoot_basic_line(1.0, [1,1,1]),
					],-1),
				]),
				
				## Hard
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return boss_health.get_health_percentage() < 0.15;
						),
					Level.CMD_Sequence.new([
						cmd_shoot_basic_line(1.0,  [0,1,1,1]),
						cmd_shoot_basic_line(1.0,   [1,0,1]),
						cmd_shoot_basic_line(1.0,  [1,1,1,0]),
						cmd_shoot_basic_line(1.0,   [1,0,1]),
					],-1),
				]),
				
				##Very Hard
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return not boss_health.is_alive();
						),
					Level.CMD_Sequence.new([
						cmd_shoot_basic_line(1.0,   [1,0,1,1]),
						cmd_shoot_basic_line(1.0,    [1,1,1]),
						cmd_shoot_basic_line(1.0,   [1,1,0,1]),
						cmd_shoot_basic_line(1.0,    [1,1,1]),
						cmd_shoot_basic_line(1.0,   [1,0,0,1]),
						cmd_shoot_basic_line(1.0,  [0,1,1,1,0]),
						Level.CMD_Wait_Seconds.new(1.25),
						cmd_shoot_basic_line(1.0,  [1,1,1,1]),
						Level.CMD_Wait_Seconds.new(1.25),
					],-1),
				]),
			]),


			## Shoots
			Level.CMD_Parallel.new([
				Level.CMD_Sequence.new([
					Level.CMD_Wait_Seconds.new(2),
					Level.CMD_Callable.new(func shoot_many_rounds():
						shoot_many.call(1 + roundi(4 * (1.0 - boss_health.get_health_percentage())))
						),
				], -1),

				Level.CMD_Sequence.new([
					Level.CMD_Wait_Callable.new(func():
						return boss_health.get_health_percentage() < 0.5
						),
					Level.CMD_Sequence.new([
						Level.CMD_Wait_Seconds_Dynamic.new(func wait_random_seconds():
							return 7 + 6 * (boss_health.get_health_percentage())
							),
						Level.CMD_Callable.new(func shoot_super():
							shoot(PROJ_ENEMY_SUPER, cannons[0], Vector3.BACK);
							shoot(PROJ_ENEMY_SUPER, cannons[cannons.size() - 1], Vector3.BACK);
							)
					], -1),
				])
			]),

			## Waits until dead
			Level.CMD_Wait_Signal.new(boss_health.dead_parameterless),
			Level.CMD_Wait_Callable.new(func wait_for_death():
				return !is_instance_valid(boss_health) or !boss_health.can_process() or !boss_health.is_alive();
				),


		]),
		Level.CMD_Await_AsyncCallable.new(func():
			Game.instance.kill_all_projectiles();
			adao.death();
			retreat();
			HUD.instance.show_boss_death();
			await VFX_Utils.make_boss_explosion(self, death_spawn_area)
			
			var t := create_tween();
			t.tween_property(graphic, "position:z", -35, 2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
			t.tween_callback(func():
				graphic.visible = false;
				)
			, self),
	])


func shoot_front(proj:PackedScene, where:Node3D):
	shoot(proj, where, Vector3.BACK);

func shoot_player(proj:PackedScene, where:Node3D):
	shoot(proj, where, Player.get_closest_direction(where.global_position, true))

func shoot(proj:PackedScene, where:Node3D, direction:Vector3):
	var shot:Node3D = InstantiateUtils.InstantiateInTree(proj, where, Vector3.ZERO, false, true);
	shot.basis = Basis.looking_at(direction, Vector3.UP, true);

func cmd_shoot_basic_line(wait:float, line:Array[int]):
	return Level.CMD_Sequence.new([
		Level.CMD_Wait_Seconds.new(wait),
		Level.CMD_Callable.new(func make_line_basic():
			shoot_line(PROJ_ENEMY_BASIC, constant_shooting_origin.global_position + Vector3(0, 0.5, 0), minf((line.size() - 1) * 1.75, 6.5), line);
			),
	])

func shoot_line(proj:PackedScene, where_origin:Vector3, line_length:float, line:Array[int]):
	var i:int = 0;
	for number:float in NumberUtils.get_equally_separated_numbers(-line_length, line_length, line.size()):
		if line[i] > 0:
			shoot_position(proj, where_origin + Vector3.RIGHT * number, Vector3.FORWARD);
		i+=1;

func shoot_position(proj:PackedScene, where:Vector3, direction:Vector3):
	var shot:ProjEnemyBasic = InstantiateUtils.InstantiatePositionRotation(proj, where, direction);
	shot.speedMultiplier = 0.5;

func get_only_random_part(faces:Array, amount:int)->Array:
	faces = faces.duplicate();
	faces.shuffle();
	return faces.slice(0, amount);

func cmd_open_faces_and_close_them(faces:Array, faces_changer:Callable = Callable()):
	var obj:Dictionary = {
		array = faces,
	}
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			if faces_changer.is_valid():
				obj.array = faces_changer.call(faces);
				print("[BOSS] Object array is %s, \twhile faces is %s" % [obj.array, faces]);
			),
		Level.CMD_Callable.new(func():
			print("[BOSS] Opening array is %s" % [obj.array]);
			open_faces(obj.array);
			),
		Level.CMD_Wait_Signal.new(destroyed_faces),
		Level.CMD_Callable.new(func():
			retreat();
			var dd:Health.DamageData = Health.DamageData.new(face_destroy_damage, self, true, true);
			boss_health.damage(dd);
			CameraShaker.screen_shake(face_destroy_shake);
			adao.vulnerable();
			set_vulnerable(true);
			),
		Level.CMD_Wait_Seconds.new(0.05),
		Level.CMD_Callable.new(func():
			stun_faces(obj.array, 0.1);
			var t:= create_tween();
			t.tween_interval(1.55);
			t.tween_callback(close_all_faces);
			t.tween_callback(set_vulnerable.bind(false));
			t.tween_interval(1.45);
			t.tween_callback(adao.finish_vulnerable);
			),
		Level.CMD_Wait_Seconds.new(1.75),
	]);

func open_faces(faces:Array):
	faces = faces.duplicate();
	for face:Boss_Trem_Face in faces:
		face.restore();
		face.set_value(Boss_Trem_Face.Value.OPENED, 0.9, 0.1, 0.65, 0.45, randf() * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
		face.set_value(Boss_Trem_Face.Value.STUNNED, 0.0, 0.05, 0.5, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
		face.get_health().dead_parameterless.connect(func():
			face.set_value(Boss_Trem_Face.Value.OPENED, 1.1, 0.05, 0.25, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
			face.set_value(Boss_Trem_Face.Value.STUNNED, 0.85, 0.15, 9.00, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
			face.explode();
			var dd := Health.DamageData.new(face.max_health, self, true, false);
			dd.overlap_invulnerablity = true;
			boss_health.damage(dd);
			faces.erase(face);
			if faces.size() == 0:
				destroyed_faces.emit();
			, CONNECT_ONE_SHOT);

func close_all_faces():
	face_center.set_value(Boss_Trem_Face.Value.OPENED, 0.0, 0.05, 0.25, 0.02, randf() * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	face_center.set_value(Boss_Trem_Face.Value.STUNNED, 0.0, 0.1, 0.5, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	face_left.set_value(Boss_Trem_Face.Value.OPENED, 0.0, 0.05, 0.25, 0.2, randf() * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	face_left.set_value(Boss_Trem_Face.Value.STUNNED, 0.0, 0.1, 0.5, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	face_right.set_value(Boss_Trem_Face.Value.OPENED, 0.0, 0.05, 0.25, 0.2, randf() * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	face_right.set_value(Boss_Trem_Face.Value.STUNNED, 0.0, 0.1, 0.5, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);

func stun_faces(faces:Array, duration:float):
	for face:Boss_Trem_Face in faces:
		face.set_value(Boss_Trem_Face.Value.OPENED, 1.0, 0.1, 0.5, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
		face.set_value(Boss_Trem_Face.Value.STUNNED, 0.65, 0.35, 4.25, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);


var retreat_tween:Tween;
func retreat():
	if won:
		return;

	deaccelerate.emit();
	if retreat_tween and retreat_tween.is_valid():
		retreat_tween.kill();
	var weight:float = get_cam_percentage();
	damage_speed = curr_speed * lerpf(-1.5, -4.0, weight);
	retreat_tween = create_tween();
	retreat_tween.tween_property(self, "damage_speed", 0.0, lerpf(3.5, 6.0, weight))\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN);
	await tween_smoke(0.0, 1.5, 0.5, Tween.TRANS_CUBIC);
	tween_smoke(1.0, 10.0, 1.5);

var smoke_tween:Tween;
func tween_smoke(end:float, duration:float, delay:float = 0.0, trans:Tween.TransitionType = Tween.TRANS_LINEAR):
	if smoke_tween and smoke_tween.is_valid():
		smoke_tween.kill();

	smoke_tween = create_tween();
	smoke_tween.tween_interval(delay);
	smoke_tween.tween_method(graphic.set_smoke_progress, graphic.old_smoke_progress, end, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT);
	await smoke_tween.finished;
