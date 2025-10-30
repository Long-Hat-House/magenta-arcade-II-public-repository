class_name LevelCameraController
extends Node3D
## Controlls a camera for a level
##
## Offers awaitable functions for controlling camera movement

enum MovementAxis {
	X,
	Z,
}

const ENVIRONMENT_HIGH_CONTRAST = preload("res://elements/environments/environment_high_contrast.tres")

static var main_camera:Camera3D;
static var instance:LevelCameraController;

static var plane0:Plane = Plane.PLANE_XZ;

var _camera_offset:Vector3 = Vector3.ZERO

var _tween_z:Tween
var _tween_x:Tween

var _speed_z:float
var _speed_x:float

var _previous_position:Vector3 #measured just so we have an idea if the camera is moving
var _last_movement:Vector3;
var last_frame_movement:Vector3:
	get:
		return _last_movement;
var _is_moving:bool:
	get:
		return _is_moving;
	set(value):
		_is_moving = value
		GlobalListener.set_var(&"traffic", value)

signal tweened_x;
signal tweened_z;
signal tweened;

var _previous_position_physics:Vector3;
var _last_movement_physics:Vector3;
var last_physics_step_movement:Vector3:
	get:
		return _last_movement_physics;

class DynamicPositioner:
	var position:Callable;
	var _cache:Vector3;
	var _tween:Tween;

	func get_position(delta:float, node_mother:LevelCameraController):
		if position.is_valid():
			_cache = position.call(delta)
		elif _tween == null and not _cache.is_zero_approx():
			_tween = node_mother.create_tween();
			_tween.tween_property(self, "_cache", Vector3.ZERO, 2)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_delay(2);
			_tween.tween_callback(func():
				self._tween = null;
				node_mother.remove_dynamic_positioner(position);
				)
		return _cache;

@onready var _dynamic: Node3D = %"Dynamic Position"
var _dynamic_getters:Array[DynamicPositioner] = [];
@onready var _manual: Node3D = $"Dynamic Position/Manual Control"
@onready var aim_reference: Marker3D = $"Dynamic Position/CenterOfScreen/AimReference"

var manual_position_unmultiplied:Vector3;
@export var manual_control_length:float = 0.25;
@export var manual_control_length_multiplier:float = 1;
@export var manual_control_velocity_relative_on:float = 2.0;
@export var manual_control_velocity_relative_off:float = 1.0;
@export var manual_control_velocity_absolute_on:float = 0.25;
@export var manual_control_velocity_absolute_off:float = 0.25;
@export var manual_control_in_multiplier:Vector3 = Vector3.ONE;
@export var manual_control_out_multiplier:Vector3 = Vector3.ONE;


func add_dynamic_positioner(vector3_getter_with_delta:Callable):
	var dynamic_getter := DynamicPositioner.new();
	dynamic_getter.position = vector3_getter_with_delta;
	_dynamic_getters.push_back(dynamic_getter);

func remove_dynamic_positioner(vector3_getter_with_delta:Callable):
	var index:int = _dynamic_getters.find_custom(func(x): x.position == vector3_getter_with_delta)
	if index > -1:
		_dynamic_getters.remove_at(index);

func get_dynamic_position(delta:float)->Vector3:
	var dyn:Vector3 = Vector3.ZERO;
	#print("[process LVL CAMERA] dynamic position calculating %s - %s [%s]" % [
		#_dg.size(),
		#_dg.reduce(func(accum:int, f:Callable):
			#if f.is_valid():
				#return accum + 1;
			#else:
				#return accum;
				#, 0),
		#Engine.get_frames_drawn()
		#]);
	for getter:DynamicPositioner in _dynamic_getters:
		dyn += getter.get_position(delta, self);
	return dyn;


# Called when the node enters the scene tree for the first time.
func _ready():
	main_camera = %Camera3D
	instance = self;

	Accessibility.high_contrast_controller.enabled_changed.connect(update_high_contrast)
	Accessibility.high_contrast_controller.background_settings_changed.connect(update_high_contrast)
	update_high_contrast()

	await get_tree().create_timer(1).timeout;
	Player.instance.just_moved_any_physics_process.connect(_moved_finger);
	Player.instance.just_released_all.connect(_finger_released);

func update_high_contrast():
	if Accessibility.get_high_contrast_enabled():
		main_camera.environment = ENVIRONMENT_HIGH_CONTRAST
		var v = clampf(Accessibility.get_high_contrast_background_visibility(),0,1)
		main_camera.environment.fog_density = 1-ease(v, 2)
		main_camera.environment.fog_light_color = Accessibility.get_high_contrast_background_color()
	else:
		main_camera.environment = null

func _process(delta:float):
	if _speed_x != 0:
		position.x += _speed_x * delta
	if _speed_z != 0:
		position.z += _speed_z * delta

	_dynamic.position = get_dynamic_position(delta);

	var pos_now:Vector3 = get_pos_with_dynamic();
	_is_moving = _previous_position != pos_now
	_last_movement = pos_now - _previous_position;
	_previous_position = pos_now;

	_set_manual_position(delta);


var fingers_movement:Vector3;
func _moved_finger(move:Vector3):
	move.y = 0;
	fingers_movement += move * manual_control_in_multiplier;
	fingers_movement = fingers_movement.limit_length(1);

func _finger_released():
	fingers_movement = Vector3.ZERO;

func _set_manual_position(delta:float):
	var on:bool = Player.instance.currentTouches.size() > 0;
	var target_pos:Vector3;
	var vel_relative:float;
	var vel_absolute:float;
	if on:
		target_pos = manual_control_in_multiplier * fingers_movement.limit_length(manual_control_length);
		vel_relative = manual_control_velocity_relative_on;
		vel_absolute = manual_control_velocity_absolute_on;
	else:
		target_pos = Vector3.ZERO;
		vel_relative = manual_control_velocity_relative_off;
		vel_absolute = manual_control_velocity_absolute_off;

	var distance:Vector3 = target_pos - manual_position_unmultiplied;
	manual_position_unmultiplied = manual_position_unmultiplied.move_toward(target_pos, (distance.length() * vel_relative + vel_absolute) * delta);
	_manual.position = manual_position_unmultiplied * manual_control_length_multiplier;

func get_manual_position():
	return manual_position_unmultiplied * manual_control_length_multiplier;

func get_pos_with_dynamic()->Vector3:
	return _dynamic.global_position;

func _physics_process(delta: float) -> void:
	var pos_now:Vector3 = get_pos_with_dynamic();
	_last_movement_physics = pos_now - _previous_position_physics;
	_previous_position_physics = pos_now;

func get_pos() -> Vector3:
	return global_position - _camera_offset

func get_stage_grid_pos(stage:LevelStageController, x:float, z:float)->Vector3:
	return get_pos() + stage.get_grid_distance(x, z);

func get_axis(axis:MovementAxis) -> float:
	match (axis):
		MovementAxis.Z:
			return get_pos().z
		MovementAxis.X:
			return get_pos().x
		_:
			return get_pos().z

func get_z() -> float:
	return get_axis(MovementAxis.Z)

func get_x() -> float:
	return get_axis(MovementAxis.X)

func get_axis_speed(axis:MovementAxis) -> float:
	match (axis):
		MovementAxis.Z:
			return _speed_z
		MovementAxis.X:
			return _speed_x
		_:
			return _speed_z

func get_screen_ground_rect()->Rect2:
	var min:Vector3 = get_screen_ground_min();
	var max:Vector3 = get_screen_ground_max();
	var size:Vector3 = max - min;
	var rect:= Rect2(min.x, min.z, size.x, size.z);
	print("GOT RECTD %s" % rect);
	return rect;

func get_screen_ground_min()->Vector3:
	return cast_point_to_zero_height(main_camera.get_viewport().get_visible_rect().position);

func get_screen_ground_max()->Vector3:
	var rect := main_camera.get_viewport().get_visible_rect();
	return cast_point_to_zero_height(rect.position + rect.size);

func cast_point_to_zero_height(screen_point:Vector2)->Vector3:
	var normal:Vector3 = main_camera.project_ray_normal(screen_point);
	var origin:Vector3 = main_camera.project_ray_origin(screen_point);
	return plane0.intersects_ray(origin, normal);

func set_offset(offset:Vector3):
	_camera_offset = offset

func cmd_position(
	target_position:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return Level.CMD_Callable.new(tween_position.bind(target_position, duration, axis, transition_type, ease_type))

func cmd_position_wait(
	target_position:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_position(target_position, duration, axis, transition_type, ease_type),
		Level.CMD_Wait_Seconds.new(duration)
	])

func cmd_position_vector(
	target_position:Vector3,
	duration:float,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
		return Level.CMD_Parallel.new([
			cmd_position(target_position.x, duration, LevelCameraController.MovementAxis.X, transition_type, ease_type),
			cmd_position(target_position.z, duration, LevelCameraController.MovementAxis.Z, transition_type, ease_type)
		], 2)

func cmd_position_vector_x_then_z(
	target_position:Vector3,
	duration_first:float, duration_second:float, wait_second_too:bool,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
		var seq:Array[Level.CMD] = [
			cmd_position_wait(target_position.x, duration_first, LevelCameraController.MovementAxis.X, transition_type, ease_type),
			cmd_position(target_position.z, duration_second, LevelCameraController.MovementAxis.Z, transition_type, ease_type)
		];
		if wait_second_too: seq.append(Level.CMD_Wait_Seconds.new(duration_second))
		return Level.CMD_Sequence.new(seq, 2)

func cmd_position_vector_wait(
	target_position:Vector3,
	duration:float,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
		return Level.CMD_Sequence.new([
			cmd_position_vector(target_position, duration, transition_type, ease_type),
			Level.CMD_Wait_Seconds.new(duration)
		])
		return

func cmd_speed(
	target_speed:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return Level.CMD_Callable.new(tween_speed.bind(target_speed, duration, axis, transition_type, ease_type))

func cmd_speed_wait(
	target_speed:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_speed(target_speed, duration, axis, transition_type, ease_type),
		Level.CMD_Wait_Seconds.new(duration)
	])

func cmd_wait_until_position(target_position:float, axis:MovementAxis = MovementAxis.Z) -> Level.CMD:
	var check_pos:Callable = func check_pos() -> bool:
		var pos = get_axis(axis)
		if pos == target_position: return true
		elif get_axis_speed(axis) < 0 and pos < target_position: return true
		elif get_axis_speed(axis) > 0 and pos > target_position: return true
		else: return false

	return Level.CMD_Wait_Callable.new(check_pos)

func cmd_speed_move(
	speed:float,
	before_stop_cmd:Level.CMD,
	axis:MovementAxis = MovementAxis.Z,
	begin_duration:float = 0,
	end_duration:float = 0,
	begin_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	begin_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT,
	end_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	end_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_speed_wait(speed, begin_duration, axis, begin_transition_type, begin_ease_type),
		before_stop_cmd,
		cmd_speed_wait(0, end_duration, axis, end_transition_type, end_ease_type),
	])

## total_duration = begin_duration + middle_movement_duration + end_duration
func cmd_speed_move_duration(
	speed:float,
	total_duration:float,
	axis:MovementAxis = MovementAxis.Z,
	begin_duration:float = 0,
	end_duration:float = 0,
	begin_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	begin_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT,
	end_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	end_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	var middle_movement_duration = total_duration - begin_duration - end_duration
	var before_stop_cmd = Level.CMD_Wait_Seconds.new(middle_movement_duration)
	return cmd_speed_move(
		speed, before_stop_cmd, axis,
		begin_duration, end_duration,
		begin_transition_type, begin_ease_type,
		end_transition_type, end_ease_type)

## Overshoots target_position for smooth stopping when end_duration is higher than 0!
func cmd_speed_move_position(
	speed:float,
	target_position:float,
	axis:MovementAxis = MovementAxis.Z,
	begin_duration:float = 0,
	end_duration:float = 0,
	begin_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	begin_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT,
	end_transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	end_ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Level.CMD:
	return cmd_speed_move(
		speed, cmd_wait_until_position(target_position), axis,
		begin_duration, end_duration,
		begin_transition_type, begin_ease_type,
		end_transition_type, end_ease_type)

func set_instant_position(position:Vector3):
	stop_camera_movement(MovementAxis.X)
	stop_camera_movement(MovementAxis.Z)
	global_position = position + _camera_offset

func stop_camera_movement(axis:MovementAxis):
	kill_camera_tween(axis)
	kill_camera_speed(axis)

func stop_all_camera_movement():
	stop_camera_movement(MovementAxis.X);
	stop_camera_movement(MovementAxis.Z);

func kill_camera_speed(axis:MovementAxis):
	match (axis):
		MovementAxis.Z:
			_speed_z = 0
		MovementAxis.X:
			_speed_x = 0

func kill_camera_tween(axis:MovementAxis):
	match (axis):
		MovementAxis.Z:
			if(_tween_z != null):
				_tween_z.kill()

		MovementAxis.X:
			if(_tween_x != null):
				_tween_x.kill()

## Kills current camera axis movement and return a new tween for controlling new movements
func create_tween_for_camera_axis(axis:MovementAxis) -> Tween:
	kill_camera_tween(axis)
	var tween = create_tween()

	match (axis):
		MovementAxis.Z:
			_tween_z = tween
		MovementAxis.X:
			_tween_x = tween

	return tween

## Creates and sets a camera tween for the position axis, returns the tweener so it can be further personalized
func tween_position(
	target_position:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Tweener:

	kill_camera_speed(axis)
	var tween:Tween = create_tween_for_camera_axis(axis)
	var property:String

	match (axis):
		MovementAxis.Z:
			property = "position:z"
			target_position += _camera_offset.z
		MovementAxis.X:
			property = "position:x"
			target_position += _camera_offset.x

	var tweener := tween.tween_property(self, property, target_position, duration).set_trans(transition_type).set_ease(ease_type)
	tween.tween_callback(func():
		match axis:
			MovementAxis.X:
				tweened_x.emit();
			MovementAxis.Z:
				tweened_z.emit();
		tweened.emit();
		)
	return tweener;


## automatically does the two tweens for a vector, shortcut for doing two tween_position for each axis. Take notice that y position is ignored.
func tween_position_vector(
	target_position:Vector3,
	duration:float,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
) -> void:
	tween_position(target_position.x, duration, MovementAxis.X, transition_type, ease_type);
	tween_position(target_position.z, duration, MovementAxis.Z, transition_type, ease_type);


## Creates and sets a camera tween for the speed axis, returns the tweener so it can be further personalized
func tween_speed(
	target_speed:float,
	duration:float,
	axis:MovementAxis = MovementAxis.Z,
	transition_type:Tween.TransitionType = Tween.TransitionType.TRANS_SINE,
	ease_type:Tween.EaseType = Tween.EaseType.EASE_IN_OUT
	) -> Tweener:

	var tween:Tween = create_tween_for_camera_axis(axis)
	var property:String

	match (axis):
		MovementAxis.Z:
			property = "_speed_z"
		MovementAxis.X:
			property = "_speed_x"

	var tweener := tween.tween_property(self, property, target_speed, duration).set_trans(transition_type).set_ease(ease_type)
	tween.tween_callback(func():
		match axis:
			MovementAxis.X:
				tweened_x.emit();
			MovementAxis.Z:
				tweened_z.emit();
		tweened.emit();
		)
	return tweener;

# Converte posição mundial para coordenada dentro do SubViewport
func world_to_viewport_position(world_pos: Vector3) -> Vector2:
	return main_camera.unproject_position(world_pos)

# Converte posição mundial para coordenada na tela principal
func world_to_screen_position(world_pos: Vector3) -> Vector2:
	var sub_viewport := main_camera.get_viewport()

	# 1. Posição no SubViewport
	var viewport_pos := world_to_viewport_position(world_pos)

	# 2. Conversão para coordenadas da tela principal
	if sub_viewport is SubViewport:
		var container:SubViewportContainer = sub_viewport.get_parent() as SubViewportContainer
		if container:
			# Considera escala e posição do container
			var container_global_rect:Rect2 = container.get_global_rect()
			var scale_factor:Vector2 = container_global_rect.size / Vector2(sub_viewport.size)

			return container_global_rect.position + (viewport_pos * scale_factor)

	return viewport_pos
