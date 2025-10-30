class_name Enemy_Statue_Ivo extends LHH3D

signal finished_rotating()
const BOSS_0 = preload("res://systems/boss/boss_0.tres")

const ENEMY_PIZZA_ROBOTO = preload("res://elements/enemy/pizza/enemy_pizza_roboto.tscn")
const ENEMY_PIZZA_ROBOTO_SHOOTER = preload("res://elements/enemy/pizza/enemy_pizza_roboto_shooter.tscn")
const ENEMY_LASER_ROBOTO = preload("res://elements/enemy/laser/enemy_laser_roboto.tscn")
const ENEMY_BOMB_ROBOTO = preload("res://elements/enemy/bomb/enemy_bomb_roboto.tscn")
const ENEMY_CHASER = preload("res://elements/enemy/chaser/enemy_chaser.tscn")
const ENEMY_BRAWNY = preload("res://elements/enemy/brawny/enemy_brawny.tscn")
const ENEMY_PIZZA_ROBOTO_RUSTY = preload("res://elements/enemy/pizza/enemy_pizza_roboto_rusty.tscn")
const ENEMY_PIZZA_ROBOTO_RUSTY_CANNON = preload("res://elements/enemy/pizza/enemy_pizza_roboto_rusty_cannon.tscn")
const ENEMY_ROBOTO_COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn")

@export var eva:Enemy_Statue_Ivo_Eva_Sidekick
var eva_circle_position:float = PI;
var eva_circle_min_radius:float;
var eva_locked:bool = true;
@export var eva_lose_position_offset:Vector3 = Vector3(-4,5,0)
@export var eva_end_position:Node3D;
@export var eva_pre_end_positions:Array[Node3D];

@export var shotScene:PackedScene;
@export var vfxScene:PackedScene;

@export var _animation_player:AnimationPlayer
@export var _bounding_box:VisibleOnScreenNotifier3D;

@export_group("level design")
@export var num_pizzas:int = 8;
@export var num_lasers:int = 4;
@export var num_bombs:int = 6;
@export var copter_line1:ChildLine3D;
@export var copter_line2:ChildLine3D;
@export var tier1_1_hp_percentage:float = 1.00;
@export var tier1_2_hp_percentage:float = 0.90;
@export var tier1_3_hp_percentage:float = 0.65;
@export var tier1_4_hp_percentage:float = 0.50;

@export_group("health and shield")
@export var _health:Health
@export var graphic:Graphic_Statue_Ivo
@export var pressable:Pressable;

@export_group("Animations and transitions")
@export var wave_shake:float:
	set(value):
		wave_shake = value;
		if graphic:
			graphic.set_wave_shake(wave_shake, wave_shake_force * Vector3(1.5,0,0.75));
@export var wave_shake_force:float;

@export var death_dancer:Node3D;
var death_dance_force:float = 0;
var death_dance_frequency:Vector2 = Vector2(1,2);
var death_dance_velocity:float = 0.5;
var death_dance_amplitude:Vector2 = Vector2(0,0);
var death_dance_rotation_lock:bool = false;
@export var death_dance_base_final:Vector3 = Vector3(0, 0, -2);
@export var death_dance_amplitude_final:Vector2 = Vector2(3,2)

@onready var charge_sfx: AkEvent3D = $Enemy_StatueIvo_EvaSidekick/ChargeSFX
@onready var shoot_sfx: AkEvent3D = $"Dancer/StaticBody3D/Shoot Origin/ShootSFX"
@onready var shoot_multiple_sfx: AkEvent3D = $"Dancer/StaticBody3D/Shoot Origin/Shoot_MultipleSFX"
@onready var first_phase_sfx: AkEvent3D = $"Dancer/Graphics - AnimationPivot_X/Graphics - AnimationPivot_Y/Graphics - AnimationTumbler/Graphics - Rotation Death Dance/Graphics - AnimationShake/graphic_ivo_estatua/FirstPhaseSFX"
@onready var second_phase_sfx: AkEvent3D = $"Dancer/Graphics - AnimationPivot_X/Graphics - AnimationPivot_Y/Graphics - AnimationTumbler/Graphics - Rotation Death Dance/Graphics - AnimationShake/graphic_ivo_estatua/SecondPhaseSFX"
@onready var high_contrast: AccessibilityHighContrastObject = $"Dancer/Graphics - AnimationPivot_X/Graphics - AnimationPivot_Y/Graphics - AnimationTumbler/Graphics - Rotation Death Dance/Graphics - AnimationShake/graphic_ivo_estatua/AccessibilityHighContrastObject"


var readied:bool;

var health:Health:
	get:
		return _health;

var shield_percentage:float:
	get:
		return shield_percentage;
	set(value):
		set_shield(value);
		shield_percentage = value;

@export var eyes_force:float:
	get:
		return eyes_force;
	set(value):
		eyes_force = value;
		if graphic:
			graphic.set_eyes(eyes_force != 0, eyes_force);


var _sneezed:bool = false;
@export var eva_height01:float = 0:
	get:
		return eva_height01;
	set(value):
		if eva and value > eva_height01:
			if eva_height01 >= 0.95:
				eva.pose();
				if not _sneezed:
					_sneezed = true;
					graphic.sneeze_big();
			else:
				eva.rise();
		eva_height01 = value;
@export var eva_rotating_vel:float = 0;


var initial_position:Vector3;
var eva_initial_position:Vector3;

func _ready():
	eyes_force = 0;
	eva_height01 = 0;
	eva_circle_min_radius = eva.position.length();
	await get_tree().process_frame;
	initial_position = position;
	readied = true;


func _process(delta: float) -> void:
	_death_dance_process(delta);
	_eva_circle_process(delta);

	if Input.is_key_pressed(KEY_K):
		health.damage(Health.DamageData.new(10));

var dd_count:float = 0;
var dd_z:Vector3 = Vector3.BACK;
var dd_d2:Vector3;
var dd_pos:Vector3;
func _death_dance_process(delta:float):
	if not readied:
		return;
	dd_count += delta * death_dance_velocity;

	var old_position:Vector3 = position;
	position = initial_position + \
			death_dance_force * death_dance_base_final + \
			Vector3(cos(dd_count * death_dance_frequency.x) * death_dance_amplitude.x * death_dance_force, 0.0, sin(dd_count * death_dance_frequency.y) * death_dance_amplitude.y * death_dance_force);
	var old_dd:Vector3 = dd_pos;
	dd_pos = Vector3(-sin(dd_count) * death_dance_amplitude.x, 0.0, cos(dd_count) * death_dance_amplitude.y) * death_dance_force;

	if not death_dance_rotation_lock:
		var d2:Vector3 = position - old_position;
		var d2_dd:Vector3 = (dd_pos - old_dd);
		
		dd_d2 += d2;
		dd_d2 = dd_d2.move_toward(Vector3.ZERO, 60 * delta);
		
		var y:Vector3 = Vector3.UP - dd_d2 * 5;
		var z:Vector3 = Vector3.BACK.slerp(d2_dd, 0.3 * sin(Vector3.BACK.angle_to(d2_dd)));
		dd_z = dd_z.move_toward(z, delta * 0.5);
		var x:Vector3 = y.cross(z);
		death_dancer.basis = death_dancer.basis.slerp(Basis(x,y,dd_z).orthonormalized(), 0.35);

func _eva_circle_process(delta:float):
	if eva_locked: return;
	eva_circle_position += delta * eva_rotating_vel * PI * 0.4;
	var circle:Vector3 = Vector3(cos(eva_circle_position), 0.0, sin(eva_circle_position));
	var radius:float = lerp(eva_circle_min_radius, 3.5, eva_height01);
	var height:Vector3 = Vector3.UP * 4 * eva_height01;

	eva.position = height + circle * radius;
	eva.set_flip(eva.position.x > 0)


func _on_health_hit(damage, health):
	graphic.shake(0.4, 0.15);


var gonna_shoot:int = 0;
func pump_then_shoot(direction:Vector3, duration:float, amount:int, angle_between_shots:float):
	eva.pump_once();
	charge_sfx.post_event();
	gonna_shoot += 1;
	eva.pumped.connect(func(canceled:bool):
		gonna_shoot -= 1;
		if gonna_shoot <= 0 and not canceled:
			shoot(direction, duration, amount, angle_between_shots);
		, CONNECT_ONE_SHOT);

func shoot(direction:Vector3, duration:float, amount:int = 1, angle_between_shots:float = 30):
	angle_between_shots = deg_to_rad(angle_between_shots);
	if pressable.is_pressed:
		return;
	direction.y = 0;
	if shotScene:
		var range:float = (amount - 1) * angle_between_shots
		var min_direction:Vector3 = direction.rotated(Vector3.UP, -range * 0.5)
		for index:int in range(amount):
			var dirThis:Vector3 = min_direction.rotated(Vector3.UP, angle_between_shots * index)
			_shoot_once(shotScene, dirThis);
	graphic.sneeze_small();
	graphic.tilt(Vector3.UP.slerp(-direction, 0.2), duration * 0.2, duration * 0.8);
	if amount > 1:
		shoot_multiple_sfx.post_event();
	else:
		shoot_sfx.post_event();

func _shoot_once(_shotScene:PackedScene, direction:Vector3):
	var shot:Node3D = InstantiateUtils.InstantiateInTree(_shotScene, graphic.get_instantiate_place(), Vector3.ZERO, false, true);
	shot.global_basis = Quaternion(Vector3.FORWARD, direction.normalized()) as Basis;
	shot.basis = shot.basis.orthonormalized();
	shot.lock_in_vector(self, Vector3.BACK, true);

func set_shield(shield01:float):
	pass;
	#graphic.set_shield(shield01);

func state_back():
	_animation_player.play(&"back")


func state_fall():
	_animation_player.play(&"fall")
	second_phase_sfx.post_event();
	set_shield(0)
	
func state_fall_immediate():
	_animation_player.play(&"fall_immediate")
	set_shield(0)

func state_rotate():
	_animation_player.play(&"rotate")
	first_phase_sfx.post_event();
	_animation_player.animation_finished.connect(
		func(animation):
			if health.is_alive() && animation == &"rotate":
				finished_rotating.emit()
				_animation_player.play(&"front")
	, Object.CONNECT_ONE_SHOT
	)

signal rose;

func state_rise():
	_animation_player.play(&"RESET");
	await get_tree().process_frame;
	_animation_player.play(&"rise");
	_animation_player.animation_finished.connect(
		func(animation):
			if health.is_alive() && animation == &"rise":
				rose.emit();
	, Object.CONNECT_ONE_SHOT)

func cmd_state_rotate():
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(state_rotate),
		Level.CMD_Wait_Signal.new(finished_rotating)
	])

func destroy_face_immediately():
	graphic.destroyed_face_immediate();
	graphic.apply_destroyed_material();

func max_shield()->void:
	pass;

func _on_health_dead(health):
	if vfxScene:
		InstantiateUtils.InstantiateInTree(vfxScene, self);


func cmd_copters(level:Level, amount:int, line:ChildLine3D)->Level.CMD:
	return Level.CMD_Callable.new(func make_copters():
		for i in range(amount):
			var copter:AI_Roboto_Copter = level.objs.create_object(ENEMY_ROBOTO_COPTER);
			copter.set_line(line);
			copter.offsetLinePosition = -i * 2;
			copter.velocityLine *= 1;
		)


func cmd_boss(level:Level)->Level.CMD:

	var getDirectionRandomLeftRight = func()->Vector3:
		var to:Vector3 = Vector3.RIGHT if randf() > 0.5 else Vector3.LEFT;
		return Vector3.BACK.slerp(to, randf() * 0.35);

	var statueShootRandomDirection = func(amount_shots:int, angle_between_shots:float):
		pump_then_shoot(getDirectionRandomLeftRight.call(), 1.25, amount_shots, angle_between_shots);

	var makeWalk = func(obj):
		var wd:AI_WalkAndDo = obj as AI_WalkAndDo;
		if wd: wd.walkAndStop = false;

	var columns:Dictionary = {
		"stl1" : -4,
		"stl3" : 2,
		"stl4" : 4
		}

	var findFreeColumn = func()->String:
		var keys:Array = columns.keys();
		var randColumn:int = randi() % keys.size();
		var now:int = (randColumn + 1) % keys.size();
		while randColumn != now:
			if level.objs.get_group_elements_count(keys[now]) <= 0: return keys[now];
			now = (now + 1) % keys.size();
		return "";



	var makeRustyPizzas:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			var freeGroup:String = findFreeColumn.call();
			if freeGroup != "":
				var x:float = columns[freeGroup];
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO_RUSTY, freeGroup, level.stage.get_grid(x, -2)));
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO_RUSTY, freeGroup, level.stage.get_grid(x, -4)));
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO_RUSTY_CANNON, freeGroup, level.stage.get_grid(x, -6)));
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO_RUSTY_CANNON, freeGroup, level.stage.get_grid(x, -8)));
			),
		Level.CMD_Wait_Seconds.new(7.5)
	],1)

	var makePizzas:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			var freeGroup:String = findFreeColumn.call();
			if freeGroup != "":
				self.num_pizzas -= 1;
				var x:float = columns[freeGroup];
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO, freeGroup, level.stage.get_grid(x, -2)));
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO, freeGroup, level.stage.get_grid(x, -4)));
				makeWalk.call(level.objs.create_object(ENEMY_PIZZA_ROBOTO_SHOOTER, freeGroup, level.stage.get_grid(x, -6)));
			),
		Level.CMD_Wait_Seconds.new(5.5)
	],1)

	var makePizzasIfPossible:Level.CMD_Branch = Level.CMD_Branch.new(func():
		return self.num_pizzas > 0;
		, makePizzas, makeRustyPizzas);

	var keepMakingPizzasIfPossible:Level.CMD = Level.CMD_Sequence.new([makePizzasIfPossible], -1);



	var makeLasers:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			var freeGroup:String = findFreeColumn.call();
			if freeGroup != "" and get_tree().get_nodes_in_group("different").size() <= 0:
				self.num_lasers -= 1;
				var x:float = columns[freeGroup];
				var laser = level.objs.create_object(ENEMY_LASER_ROBOTO, freeGroup, level.stage.get_grid(x, -2)) as AI_WalkAndDo;
				laser.add_to_group("different")
				laser.distanceMax = 13
			),
		Level.CMD_Wait_Seconds.new(9)
	],1)

	var makeLasersIfPossible:Level.CMD_Branch = Level.CMD_Branch.new(func():
		return num_lasers > 0;
		, makeLasers, makeRustyPizzas);


	var keepMakingLasersIfPossible:Level.CMD = Level.CMD_Sequence.new([makeLasersIfPossible], -1);

	var makeBombs:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			var freeGroup:String = findFreeColumn.call();
			if freeGroup != "":
				self.num_bombs -= 1;
				var x:float = columns[freeGroup];
				level.objs.create_object(ENEMY_BOMB_ROBOTO, freeGroup, level.stage.get_grid(x, -2)).add_to_group("different");
			),
		Level.CMD_Wait_Seconds.new(8.5)
	],1)

	var makeBombsIfPossible:Level.CMD = Level.CMD_Branch.new(func():
		return num_bombs > 0;
		, makeBombs, makeRustyPizzas);

	var keepMakingBombsIfPossible:Level.CMD = Level.CMD_Sequence.new([makeBombsIfPossible], -1);

	var slowShooting:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(statueShootRandomDirection.bind(1, 15.0)),
		Level.CMD_Wait_Seconds.new(3),
	],-1)

	var fastShooting:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(statueShootRandomDirection.bind(1, 15.0)),
		Level.CMD_Wait_Seconds.new(1.5),
	],-1)

	var getNumberOfShots:Callable = func get_number_of_shots()->int:
		var healthForce01:float = 1.0 - health.get_health_percentage();
		var amountShots:int = ceili(remap(1.0 - health.get_health_percentage(), 0.5, 1.0, 0, 4));
		return amountShots;

	var getAngle:Callable = func get_angle(number_of_shots:int)->float:
		return remap(number_of_shots, 2, 6, 75, 45);

	var slowMultipleShooting:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			var myPos:Vector3 = self.global_position;
			var direction:Vector3 = Player.instance.get_closest_position(myPos) - myPos;
			var amount:int = getNumberOfShots.call();
			shoot(direction, 1.25, amount, getAngle.call(amount));
			),
		Level.CMD_Wait_Seconds.new(2),
	],-1)

	var fastMultipleShooting:Level.CMD_Sequence = Level.CMD_Sequence.new([
		Level.CMD_Wait_Seconds.new(1.25),
		Level.CMD_Callable.new(func():
			var myPos:Vector3 = self.global_position;
			var direction:Vector3 = Player.instance.get_closest_position(myPos) - myPos;
			var amount:int = getNumberOfShots.call();
			shoot(direction, 1.25, amount, getAngle.call(amount));
			),
	],-1)

	var justShot:Array[bool] = [false];

	return Level.CMD_Sequence.new([

		Level.CMD_Music_Event.new(AK.EVENTS.MUSIC_LEVEL1_GAMEPLAY_END),
		##Turned the challenge into a boss ---

		# BOSS INTRO
		level.cam.cmd_position_vector_wait(level.stage.get_grid(0,-4), 1.8),
		cmd_state_rotate(),

		# SKIPABLE INTRO DIALOGUE
		Level.CMD_Branch.new(
			func():
				if OS.has_feature("editor"):
					return Input.is_key_pressed(KEY_S)
				return false
				,

			Level.CMD_Sequence.new([])
				# SKIPPED DIALOGUE
				,

			Level.CMD_Sequence.new([
				# INTRO DIALOGUE
				cmd_copters(level, 6, copter_line1),
				eva.cmd_play_state(eva.STATE_HIDDEN, eva.DIAL_HIDDEN),
				Level.CMD_Wait_Seconds.new(0.25),
				Level.CMD_Callable.new(high_contrast.change_group.bind(&"enemy")),
				eva.cmd_play_state(eva.STATE_APPEAR1, eva.DIAL_APPEAR1),
				cmd_copters(level, 4, copter_line2),
				Level.CMD_Wait_Seconds.new(0.5),
				eva.cmd_play_state(eva.STATE_APPEAR2, ""),
				eva.cmd_play_state(eva.STATE_SPEECH, eva.DIAL_INTRO),
			])
		),

		## CHALLENGE BEGIN
		level.cam.cmd_position_vector_wait(level.stage.get_grid(0,-2), 2),
		eva.cmd_play_state(eva.STATE_SPEECH, eva.DIAL_DURING, true),
		Level.CMD_Callable.new(func():
			health.release_min_health()
			shield_percentage = 0.1
			create_tween().tween_property(self, "eyes_force", 0.8, 4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
			HUD.instance.show_boss_life(BOSS_0, func get_boss_life(): return health.get_health_percentage());
			health.damage_reduction = 0;
			),

		# THE CHALLENGE
		Level.CMD_Parallel.new([
			# The statue shield time limit
			Level.CMD_Process.new(func(delta:float):
				shield_percentage = remap(health.get_health_percentage(), 0.5, 1.0, 1.0, 0.0);
				return false
				),

			# The statue health phases
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(2.5),
				#Phase 1
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return self != null and health.get_health_percentage() < tier1_1_hp_percentage),
					Level.CMD_Parallel.new([slowShooting]),
				],1),
				#Phase 2
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return self != null and health.get_health_percentage() < tier1_2_hp_percentage),
					Level.CMD_Parallel.new([keepMakingPizzasIfPossible, slowShooting]),
				],1),
				#Phase 2
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return self != null and health.get_health_percentage() < tier1_3_hp_percentage),
					Level.CMD_Parallel.new([keepMakingPizzasIfPossible, keepMakingBombsIfPossible, slowShooting]),
				],1),
				#Phase 3
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return self != null and health.get_health_percentage() < tier1_4_hp_percentage),
					Level.CMD_Parallel.new([keepMakingPizzasIfPossible, keepMakingLasersIfPossible, keepMakingBombsIfPossible, fastShooting]),
				],1),
			]),
		]),
		## Transition to second phase
		Level.CMD_Callable.new(func():
			HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash)

			Game.instance.kill_all_enemies();
			Game.instance.kill_all_projectiles();
			eva._change_state(eva.STATE_SPEECH)
			eva.flow_player.kill_flow()

			state_fall();
			graphic.apply_destroyed_material();
			eyes_force = 0;
			health.invulnerable = true;
			eva.first_shock();
			),
		Level.CMD_Wait_Seconds.new(0.5),
		Level.CMD_Parallel.new([
			eva.cmd_play_state(eva.STATE_SPEECH2, eva.DIAL_2TRANS),
			Level.CMD_Wait_Seconds.new(2.35),
		], 2),
		Level.CMD_Parallel_Complete.new([
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(func():
					state_rise();
					),
				Level.CMD_Wait_Seconds.new(3.5),
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(0.85),
				cmd_copters(level,10, copter_line2),
			])
		]),
		Level.CMD_Callable.new(func():
			eva_circle_position = PI;
			eva.return_cable();
			eva.state_finished.connect(func():
				eva.rise();
				eva_locked = false;
				, CONNECT_ONE_SHOT)
			),
		Level.CMD_Wait_Signal.new(rose),
		Level.CMD_Callable.new(func():
			health.invulnerable = false;
			),


		## Second phase
		Level.CMD_Parallel.new([
			Level.CMD_Wait_Callable.new(func(): return not health.is_alive()),

			##Eva
			Level.CMD_Sequence.new([
				##Eva pose of eva_height01
				Level.CMD_Wait_Seconds.new(0.25),

				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return health.get_health_percentage() < 0.2),
					Level.CMD_Sequence.new([
						Level.CMD_Callable.new(func():
							eva.laugh();
							eva.play_dialogue(eva.DIAL_2_IDLE, true);
							),
						Level.CMD_Wait_Forever.new(),
					]),
				]),

				Level.CMD_Callable.new(func():
					eva.laugh_but_worried();
					),
				Level.CMD_Wait_Forever.new(),
			]),

			##Death dance
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(func():
					var t = create_tween();
					t.set_parallel(true);
					t.tween_property(self, "death_dance_force", 1, 2.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
					t.tween_property(self, "death_dance_amplitude", death_dance_amplitude_final, 5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
					),
				Level.CMD_Wait_Seconds.new(4.5),
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func(): return self != null and health.get_health_percentage() < 0.40),
					Level.CMD_Parallel.new([slowMultipleShooting]),
				],1),
				Level.CMD_Parallel.new([
					Level.CMD_Sequence.new([
						Level.CMD_Callable.new(func():
							death_dance_velocity *= 2;
							),
						Level.CMD_Wait_Forever.new(),
					]),
					Level.CMD_Parallel.new([fastMultipleShooting]),
				],1),
				Level.CMD_Wait_Forever.new(),
			])
		]),

		# DEATH SEQUENCE
		Level.CMD_Callable.new(func():
			eva_rotating_vel = 0;
			death_dance_velocity = 0;
			graphic.shake(HUD.boss_flash_duration + 4.0, 0.08)
			HUD.instance.show_boss_death()
			HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
			Game.instance.kill_all_projectiles();
			eva.stop_dialogue();
			eva.shock();
			),
		Level.CMD_Wait_Seconds.new(1),
		Level.CMD_Parallel_Complete.new([
			Level.CMD_Callable.new(func():
				set("eva_circle_position", fposmod(eva_circle_position, 2 * PI));
				var t = self.create_tween();
				t.tween_property(self, "eva_circle_position", PI, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
				await t.finished;
				if !is_instance_valid(self): return;
				t = self.create_tween();
				t.tween_property(self, "eva_height01", 0, 2.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
				await t.finished;
				),
			Level.CMD_Callable.new(func():
				eva_locked = true;
				eva.reparent(self.get_parent());
				## Eva go to a less awkward position!!
				var et:Tween = eva.create_tween();
				var pre_end_position:Node3D = eva_pre_end_positions.reduce(func(x:Node3D, y:Node3D):
					if x == null:
						return y;
					elif y == null:
						return x;
					var distX:Vector3 = eva.global_position - x.global_position;
					var distY:Vector3 = eva.global_position - y.global_position;
					if distX.length_squared() < distY.length_squared():
						return x;
					else:
						return y;
					, null);
				et.tween_property(eva, "global_position", pre_end_position.global_position, 1.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.1);


				death_dance_rotation_lock = true;
				var tw:Tween;
				tw = self.create_tween();
				tw.set_parallel();
				#tw.tween_property(eva, "global_position:z", self.global_position.z, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART);
				#tw.tween_property(eva, "global_position:y", -1.0, 1.4).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR);
				tw.tween_property(self, "rotation:y", -4 * PI, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
				tw.tween_property(self, "death_dance_force", 0, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
				),
		]),
		Level.CMD_Wait_Seconds.new(1.8),
		Level.CMD_Callable.new(func():
			VFX_Utils.make_boss_explosion(self, _bounding_box);
			),
		Level.CMD_Wait_Seconds.new(HUD.boss_flash_duration),
		Level.CMD_Wait_Seconds.new(0.25),
		Level.CMD_Callable.new(func():
			create_tween().tween_property(self, "eyes_force", 0, 1.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
			),
		Level.CMD_Wait_Seconds.new(0.5),
		Level.CMD_Callable.new(func():
			graphic.destroyed_face();
			),
		Level.CMD_Wait_Seconds.new(0.1),
		Level.CMD_Callable.new(func():
			state_fall();

			var et:Tween = eva.create_tween();
			et.tween_callback(func():
				eva.play_dialogue(eva.DIAL_2_END);
				).set_delay(0.15);
			et.tween_property(eva, "global_position", eva_end_position.global_position, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_delay(0.1);
			## Eva leaving the scene
			et.tween_interval(0.5);
			var to_where:Vector3 = Vector3.LEFT if eva_end_position.global_position < self.global_position else Vector3.RIGHT;
			to_where *= 10;
			et.tween_property(eva, "position", to_where, 5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).as_relative();
			),
		Level.CMD_Wait_Seconds.new(3.25),
	]);


func _on_pressable_pressed_process(touch: RefCounted, delta: float) -> void:
	return;
	## damage here because damage on pressed will not have the effect :P, just put this on pressed (the pass below) if that's the case.
	#if !graphic._shield_disabled:
		#touch.health.damage(Health.DamageData.new(1, self));
