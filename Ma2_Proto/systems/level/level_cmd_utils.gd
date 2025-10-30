class_name Level_Cmd_Utils extends Node

const ALTAR = preload("res://elements/powerups/altar/powerup_altar.tscn")

const HOLD_BLUE = preload("res://elements/powerups/button/powerup_weapon_button_hold_blue.tscn")
const HOLD_GREEN = preload("res://elements/powerups/button/powerup_weapon_button_hold_green.tscn")
const HOLD_RED = preload("res://elements/powerups/button/powerup_weapon_button_hold_red.tscn")
const HOLD_YELLOW = preload("res://elements/powerups/button/powerup_weapon_button_hold_yellow.tscn")

const TAP_BLUE = preload("res://elements/powerups/button/powerup_weapon_button_tap_blue.tscn")
const TAP_GREEN = preload("res://elements/powerups/button/powerup_weapon_button_tap_green.tscn")
const TAP_RED = preload("res://elements/powerups/button/powerup_weapon_button_tap_red.tscn")
const TAP_YELLOW = preload("res://elements/powerups/button/powerup_weapon_button_tap_yellow.tscn")

const HOLD_FIRE_RATE = preload("res://elements/powerups/button/holdable_button_fire_rate.tscn")
const HOLD_WARMUP = preload("res://elements/powerups/button/holdable_button_warmup.tscn")
const HOLD_LVLUP = preload("res://elements/powerups/button/holdable_button_holdlvlup.tscn")

static func create_multiple_altars(altarScene:PackedScene, objectsInAltars:Array, level:Level, group:String, posFirst:Vector3, distanceBetween:Vector3, speed:Vector3):
	var pos:Vector3 = posFirst;
	print("[Altar_cmd] making altar on %s while camera is on %s" % [pos, level.cam.get_pos()]);
	for carried in objectsInAltars:
		if carried is Dictionary:
			var use_object:bool = true;
			if carried["condition"
			]:
				use_object = carried["condition"].call();
			if use_object:
				if carried["fallback"] and not carried["fallback"] is PackedScene:
					carried["fallback"].queue_free();
				carried = carried["object"];
			else:
				if carried["object"] and not carried["object"] is PackedScene:
					carried["object"].queue_free();
				carried = carried["fallback"];
		var altar:Altar = level.objs.create_object(altarScene, group, pos);
		var thing = carried;
		if carried is Callable:
			thing = carried.call()
		elif carried is PackedScene:
			thing = level.objs.create_object(carried);
		if thing:
			altar.carry(thing);
		if altar is AltarWalkAndOpen:
			altar.direction = speed;
		pos += distanceBetween;

### Objects in altars can be simply instantiated altars
### Or each entry can be a dictionary with:
### --- object: the object itself
### --- condition: the condition for the object to be there, if it is false, no object and no altar will appear
### --- fallback: if the condition is false, this object will be there instead
###	if condition is false, object will be queued_free(), if not, fallback will be queued_free().
static func cmd_multiple_altars(altarScene:PackedScene, objectsInAltars:Array, level:Level, group:String, pos_first_grid:Vector2, distanceBetween:Vector3, speed:Vector3)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			create_multiple_altars(
				altarScene, objectsInAltars, level, group,
				level.stage.get_grid(pos_first_grid.x, pos_first_grid.y),
				distanceBetween, speed
				);
			),
		level.objs.cmd_wait_group(group),
		##The wait is here because unfortunate BUT we cant remove as lots of levels use like this
	]);

static func cmd_multiple_altars_in_camera(altarScene:PackedScene, objectsInAltars:Array, level:Level, group:String, pos_first_grid:Vector2, distanceBetween:Vector3, speed:Vector3)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			create_multiple_altars(
				altarScene, objectsInAltars, level, group,
				level.cam.get_pos() + level.stage.get_grid_distance(pos_first_grid.x, pos_first_grid.y),
				distanceBetween, speed
				);
			),
		## Important you should wait if you want to wait
		##level.objs.cmd_wait_group(group),
	]);

static func cmd_multiple_altars_right_to_left(altarScene:PackedScene, objectsInAltars:Array, level:Level, group:String = "", offset:Vector3 = Vector3.ZERO)-> Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Wait_Seconds.new(0.5),
		Level.CMD_Callable.new(func():
			create_multiple_altars(
				altarScene,
				objectsInAltars,
				level,
				group,
				level.cam.get_pos() + Vector3(7.5, 0, 22) + offset,
				Vector3(2, 0, -5),
				(Vector3.LEFT * 4.5 + Vector3.FORWARD * 0.5).normalized()
			);
			),
	]);

static func cmd_multiple_altars_left_to_right(altarScene:PackedScene, objectsInAltars:Array, level:Level, group:String = "")-> Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Wait_Seconds.new(0.5),
			Level.CMD_Wait_Seconds.new(0.5),
			Level.CMD_Callable.new(func():
				create_multiple_altars(
					altarScene,
					objectsInAltars,
					level,
					group,
					level.cam.get_pos() + Vector3(-7.5, 0, 22),
					Vector3(-2, 0, -5),
					(Vector3.RIGHT * 4.5 + Vector3.FORWARD * 0.5).normalized(),
				);
				),
	]);

static func cmd_show_semaphor(
	semaphorScene:PackedScene,
	level:Level, text:String,
	condition_on:Callable, if_ends_then_semaphor_success:Level.CMD,
	success_cmd:Level.CMD, fail_cmd:Level.CMD,
	onDurationNeeded:float = 1)->Level.CMD:
	var instance:DisplaySemaphor = semaphorScene.instantiate();
	instance.set_display_id(text)
	var values:Array[float] = [
		0, ## [0] time count
		0, ## [1] is inside semaphor
		];
	var remove_instance = func():
		instance.queue_free();
	var was_success:Array[bool] = [false];
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			HUD.instance.add_child(instance);
			),
		Level.CMD_Process.new(func(delta:float): ## Wait for the condition to be totally on for a while
			var is_on = condition_on.call();
			if is_on:
				values[0] += delta / onDurationNeeded;
				if values[0] >= 1: values[1] = 1;
			else:
				values[0] = 0;
			instance.set_condition(is_on);
			instance.set_display_progress(values[0]);
			instance.set_inside_semaphor(values[1] > 0);
			return values[1] > 0;
			),
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Process.new(func(delta:float): ## Wait for the condition to be false
					var is_on = condition_on.call();
					instance.set_condition(is_on);
					instance.set_display_progress(1 if is_on else 0);
					instance.set_inside_semaphor(is_on);
					return not is_on; ## if not is on then...
					),
				## ... fail it
				Level.CMD_Callable.new(remove_instance),
				Level.CMD_Callable.new(func(): was_success[0] = false),
			]),
			Level.CMD_Sequence.new([
				if_ends_then_semaphor_success, ## if left the parallel then success
				Level.CMD_Callable.new(remove_instance),
				Level.CMD_Callable.new(func(): was_success[0] = true),
			]),
		]),
		Level.CMD_Branch.new(func(): return was_success[0], success_cmd, fail_cmd),
	]);

static func cmd_level_waves(level:Level, group:String, level_waves:Array[LevelWave], stage_pieces:Array[PackedScene], camera_velocity_per_distance:float = 0.75, safety_distance:float = 12)->Level.CMD:
	return Level.CMD_Callable.new(func():
		var pos:Vector3 = level.stage.get_grid(0,0);
		var distance:float = 0;
		for wave:LevelWave in level_waves:
			wave.position_self(pos);
			var waveDistance := wave.get_distance();
			print("Found wave %s with distance %s" % [wave, waveDistance]);
			pos.z -= waveDistance.z;
			distance += waveDistance.z;
		print("waves: total distance %s, pos.z of the camera %s" % [distance, pos.z])
		level.stage.fill_with(stage_pieces, distance + safety_distance);
		level.stage.repivot();
		level.cam.tween_position(pos.z, distance * camera_velocity_per_distance, LevelCameraController.MovementAxis.Z, Tween.TRANS_LINEAR);

		level.cmd_array([
			Level.CMD_Wait_Seconds.new(distance * camera_velocity_per_distance),
			level.objs.cmd_wait_group(group),
			]);
		);

func make_enemy_wad_line_instant(level:Level, walk_and_do_scene:PackedScene, where:Vector3, dir:Vector3, quantity:int, group:String = "", interval:float = 1, vel_multiplier:float = 1, each:Callable = Callable()):
	var dist:Vector3 = -dir * interval;
	for i in range(quantity):
		var pizza:AI_WalkAndDo = level.objs.create_object(walk_and_do_scene, group, where + dist * i);
		pizza.walkVelocity = dir.normalized() * pizza.walkVelocity.length() * vel_multiplier;
		if each:
			each.call(pizza);

func cmd_enemy_wad_line_instant(level:Level, walk_and_do_scene:PackedScene, where:Vector3, dir:Vector3, quantity:int, group:String = "", interval:float = 1, vel_multiplier:float = 1, each:Callable = Callable()):
	return Level.CMD_Callable.new(make_enemy_wad_line_instant.bind(
		level, walk_and_do_scene,
		where, dir,
		quantity, group,
		interval, vel_multiplier,
		each))

func cmd_enemy_wad_line_timed(level:Level, walk_and_do_scene:PackedScene, where:Vector3, dir:Vector3, quantity:int, group:String = "", interval:float = 1, vel_multiplier:float = 1, each:Callable = Callable())->Level.CMD:
	var arr:Array[Level.CMD] = [];
	for i in range(quantity):
		if arr.size() > 0:
			arr.push_back(Level.CMD_Wait_Seconds.new(interval));
		arr.push_back(Level.CMD_Callable.new(func():
			var pizza:AI_WalkAndDo = level.objs.create_object(walk_and_do_scene, group, where);
			pizza.walkVelocity = dir.normalized() * pizza.walkVelocity.length() * vel_multiplier;
			if each:
				each.call(pizza);
			))
	return Level.CMD_Sequence.new(arr);
