class_name Boss_Cachorro extends LHH3D

@onready var boss_health:Health = $"BossCachorroBody/BossHealth";
@onready var body: AnimatableBody3D = $BossCachorroBody
@onready var items:Node3D = $"BossCachorroDisco/Items";
@onready var screen_attack_preview: ScreenAttackPreview = $BossCachorroBody/ScreenAttackPreview
@onready var plate: Boss_Cachorro_Item_Distributor = $ItemDistributor
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var graphic: Graphic_Boss_Cachorro = $BossCachorroBody/boss_cachorro
@onready var state_machine: SimpleStateMachine = $AnimationsStateMachine
@onready var sidekick: Boss_Cachorro_Turing_Sidekick = graphic.sidekick;
@onready var dog_anim: AnimationPlayer = graphic.animation;
@onready var explosion_aabb: VisibleOnScreenNotifier3D = $BossCachorroBody/boss_cachorro/explosion_aabb

@onready var shooter_center: Boss_Shooter = $ShooterCenter
@onready var shooter_center_secondary: Boss_Shooter = $ShooterCenter_Secondary

@export var suck_acceleration:float = 10;
@export var suck_max_velocity:float = 8;
var suck_velocity:float;
@export var foods_to_kill:int = 6;
@export var first_food:Node3D;
var food_parent:Node3D;
@export var base_duration_screen_attack:float = 13;
@export var duration_extra_time_per_step:float = 1;
@export var sequence_screen_attack_mult:float = 0.75;

@export var sfx_appear:WwiseEvent;
@export var sfx_death:WwiseEvent;
@export var sfx_eat:WwiseEvent;
@export var sfx_attack:WwiseEvent;
@export var sfx_suck:AkEvent3DLoop;
@export var sfx_warning:AkEvent3DLoop;


@export var lasers:Array[Enemy_LaserArea];
@export var lasers_rotation:ConstantRotation;

var follow_camera:bool;
var sucked:Node3D;



var step:int = 0;

signal eaten_food;

func _ready() -> void:
	food_parent = first_food.get_parent_node_3d();
	food_parent.remove_child(first_food);
	_feedback_start_position();
	sidekick.visible = false;

	plate.item_destroyed.connect(_on_food_plate_item_destroyed);

	graphic.shot_there.connect(Player.instance.damage.bind(1));

	state_machine.add_state_simplest("dead",
		func dead_condition():
			return !boss_health.is_alive();
			,
		func dead_transition():
			sidekick.death(get_parent_node_3d());
			graphic.set_dead_anim(true);
			graphic.start_dialogue(graphic.dialogue_end);
			,
		)
	state_machine.add_state_physics("sucking",
		_is_sucking,
		func sucking_transition():
			sidekick.start_pull();
			await sidekick.pulled;
			graphic.back_to_idle();
			sfx_suck.start_loop();
			graphic.set_suck_anim(true);
			,
		func sucking_leave():
			sfx_suck.stop_loop();
			graphic.set_suck_anim(false);
			,
		func sucking_process_physics(delta:float):
			_pull_food_physics_process(delta);
			,
		)
	state_machine.add_state("attack",
		_is_attacking,
		func attacking_transition():
			sidekick.start_attack();
			sfx_warning.start_loop();
			graphic.back_to_idle();
			graphic.set_attack_anim(true);
			,
		func attacking_leave():
			sfx_warning.stop_loop();
			graphic.set_attack_anim(false);
			,
		Callable(),
		func attacking_process_physics(delta:float):
			if screen_attack and screen_attack.is_valid():
				screen_attack.custom_step(delta);
			,
		)
	state_machine.add_transition_state("eating",
		func eating_transition():
			graphic.start_dialogue(null);
			graphic.set_eat_anim(true);
			sfx_eat.post(body);
			await get_tree().create_timer(0.75).timeout;
			boss_health.damage(Health.DamageData.new(boss_health.get_max_amount() / foods_to_kill, self, true, false));
			graphic.set_eat_anim(false);
			graphic.start_dialogue(graphic.dialogue_hurt);
			await sidekick.eat();
			,
		func eating_leave():
			graphic.set_eat_anim(false);
			,
		)
	state_machine.add_state("idle", Callable(),
		func idle_transition():
			sidekick.idle();
			graphic.back_to_idle();
			graphic.start_dialogue(graphic.dialogue_idle);
			,
		func idle_leave():
			,
			);

func cmd_boss()->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(start_boss),
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Signal.new(eaten_food),
					Level.CMD_Wait_Callable.new(func check_have_no_food():
						return not plate.has_food_in_plate();
						),
				]),
				Level.CMD_Callable.new(do_next_step),
				Level.CMD_Callable.new(func():
					_set_shoot_intensity(self.step);
					),
				Level.CMD_Wait_Seconds.new(2),
			], -1),
			Level.CMD_Wait_Signal.new(boss_health.dead_parameterless)
		]),
		Level.CMD_Await_AsyncCallable.new(end_boss, self),
		Level.CMD_Callable.new(finish_boss),
	])

func _process(delta: float) -> void:
	if follow_camera:
		position += LevelCameraController.instance.last_frame_movement;

func _physics_process(delta: float) -> void:
	if Input.is_key_label_pressed(KEY_K):
		boss_health.damage(Health.DamageData.new(20));

func boss_into_screen():
	sidekick.visible = true;
	anim.play("start_boss");
	sfx_appear.post(body);

func start_boss():
	sidekick.visible = true;
	_feedback_start_boss();
	plate.shuffle();
	food_parent.add_child(first_food);
	TransformUtils.tween_fall(first_food, create_tween());

func end_boss():
	sfx_death.post(body);
	block_screen_attack_forever();
	stop_shooting();
	Game.instance.kill_all_projectiles();
	HUD.instance.show_boss_death(false)
	interrupt_screen_attack();
	for laser in lasers:
		laser.queue_free();
	await VFX_Utils.make_boss_explosion($BossCachorroBody/boss_cachorro, explosion_aabb);
	graphic.set_really_dead_anim(true);

func finish_boss():
	follow_camera = false;


func eat(food:Node3D):
	print("[DOG] Will eat food %s (items left:%s)" % [food, plate.get_amount_items_on_plate()]);
	if food and is_instance_valid(food) and food.get_parent() != null:
		print("[DOG] Ate food %s (items left:%s)" % [food, plate.get_amount_items_on_plate()]);
		food.queue_free();
		state_machine.do_state("eating")

		if _is_food(food): ## Used to be like this
			eaten_food.emit();

		if plate.get_amount_items_on_plate() <= 1:
			eaten_food.emit();

var _is_threatening:bool = false;
func start_threat(time_out:float):
	_is_threatening = true;
	start_screen_attack(time_out);

func is_threatening()->bool:
	return _is_threatening;

func stop_threat()->void:
	_is_threatening = false;
	interrupt_screen_attack();

var screen_attack:Tween;
var _last_used_screen_attack_time_out:float = 5;
func start_screen_attack(time_out:float):
	if !boss_health.is_alive():
		return;
	if screen_attack and screen_attack.is_valid():
		screen_attack.kill();
	screen_attack = create_tween();
	_last_used_screen_attack_time_out = time_out;
	screen_attack.tween_method(func(value:float):
		screen_attack_preview.set_closed(value);
		graphic.set_emission(value);
		, 0.0, 1.0, time_out);
	screen_attack.tween_callback(func():
		sfx_attack.post(body);
		graphic.shoot_ball_to_player(LevelCameraController.main_camera)
		)
	screen_attack.tween_interval(0.5);
	screen_attack.tween_callback(start_screen_attack.bind(time_out * sequence_screen_attack_mult))
	screen_attack.pause();

func interrupt_screen_attack()->bool:
	if screen_attack and screen_attack.is_valid():
		screen_attack.kill();
		screen_attack_preview.interrupt();
		screen_attack_preview.set_closed(0.0);
		return true;
	else:
		return false;

func continue_threat(time:float, time_out:float):
	if interrupt_screen_attack():
		await get_tree().create_timer(time).timeout;
		if not _screen_attack_block and is_threatening():
			start_screen_attack(time_out)

var _screen_attack_block:bool;
func block_screen_attack_forever():
	interrupt_screen_attack();
	_screen_attack_block = true;

func do_next_step():
	step += 1;

	stop_threat();

	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash);

	plate.add_items(1 + plate.get_items_total() / foods_to_kill);
	await plate.all_items_fell;
	start_threat(base_duration_screen_attack + step * duration_extra_time_per_step);

func _get_sucked_from_area(area:Area3D)->Node3D:
	print("[DOG] Area %s, owner %s, parent %s" % [area, area.owner, area.get_parent_node_3d()]);
	if area != null:
		if area.owner != null:
			return area.owner;
		else:
			return area;
	else:
		return null;

func _pull_food_physics_process(delta:float):
	if is_instance_valid(sucked):
		var dist:Vector3 = self.global_position - sucked.global_position;
		dist.y = 0;
		suck_velocity = minf(suck_max_velocity, suck_velocity + suck_acceleration * delta);
		sucked.global_position += dist.normalized() * suck_velocity * delta;
	else:
		suck_velocity = 0;



func _on_food_area_area_entered(area: Area3D) -> void:
	sucked = _get_sucked_from_area(area);


func _on_food_area_area_exited(area: Area3D) -> void:
	sucked = null;

func _on_food_plate_item_destroyed() -> void:
	if not plate.has_food_in_plate():
		eaten_food.emit();


var eat_tween:Tween;
func _on_food_receive_area_area_entered(area: Area3D) -> void:
	if eat_tween and eat_tween.is_running():
		return;
	var elem:Node3D = _get_sucked_from_area(area);
	if elem == sucked:
		continue_threat(3, _last_used_screen_attack_time_out * 0.9);
		sucked.process_mode = Node.PROCESS_MODE_DISABLED;
		eat_tween = create_tween();
		eat_tween.tween_property(sucked, "scale", Vector3.ONE * 0.01, 0.4);
		eat_tween.tween_callback(eat.bind(sucked));

func _on_item_distributor_item_fell(item: Node3D) -> void:
	if _is_food(item):
		start_screen_attack(base_duration_screen_attack + step * duration_extra_time_per_step);

func _is_food(item:Node3D)->bool:
	return item.name.containsn("food");

func _check_tween(t:Tween):
	if t and t.is_valid():
		t.kill();

var shoot_tween:Tween;
var shoot_tween2:Tween;
func _set_shoot_intensity(intensity:int):
	_check_tween(shoot_tween);
	_check_tween(shoot_tween2);

	shoot_tween = create_tween();
	shoot_tween.tween_interval(2.0 / intensity);
	shoot_tween.tween_callback(shooter_center.shoot_random);
	shoot_tween.set_loops(-1);

	if intensity > 2:
		shoot_tween2 = create_tween();
		shoot_tween2.tween_interval(10.0 / intensity);
		shoot_tween2.tween_callback(func():
			var amount:int = (intensity / 3) + 1;
			while amount > 0:
				shooter_center_secondary.shoot_random();
				amount -= 1;
			);
		shoot_tween2.set_loops(-1);

	var laser_tween := create_tween();
	var laser:int = intensity - 2;
	if laser < lasers.size():
		if laser >= 0 and is_instance_valid(lasers[laser]):
			lasers[laser].pre_laser();
			laser_tween.tween_interval(1.5);
			laser_tween.tween_callback(lasers[laser].start_laser);
	else:
		laser_tween.tween_property(lasers_rotation, "angleVelocity", deg_to_rad(5), 1.0).as_relative();

func stop_shooting():
	_check_tween(shoot_tween);
	_check_tween(shoot_tween2);


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if not boss_health.is_alive():
		queue_free();

func _is_sucking()->bool:
	return sucked != null or (eat_tween != null and eat_tween.is_running());

func _is_attacking()->bool:
	return screen_attack != null and screen_attack.is_valid();

func _feedback_start_position():
	anim.play("first_frame");

func _feedback_start_boss():
	pass
