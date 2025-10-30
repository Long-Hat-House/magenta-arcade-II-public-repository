extends Node3D

@export var acceleration_multiplier:float = 5;
@export var speed_multiplier:float = 1.1;
@export var speed_reduce:float = 2;
@export var speed_max:float = 8;
var speed:Vector3;
@export var seconds_total:float = 10;
@export var time_out_of_screen:float = 1.25;
@export var each_damage_take_seconds:float = 1;
@export var vfx_hit:PackedScene;
@onready var scaler: Node3D = $ConstantRotation/Scaler

@export_category("Audio")
@export var _sfx_play:WwiseEvent
@export var _sfx_stop:WwiseEvent
@export var _sfx_parameter:WwiseRTPC

var out_of_screen_count:float = 0.0;

var existence_percentage:float:
	set(value):
		existence_percentage = value;
		if _sfx_parameter: _sfx_parameter.set_value(self, existence_percentage)
		_set_scale(existence_percentage, pump_value);
	get:
		return existence_percentage;

var pump_value:float:
	set(value):
		pump_value = value;
		_set_scale(existence_percentage, pump_value);
	get:
		return pump_value;

func _set_scale(existence:float, pump_value:float)->void:
	existence = Tween.interpolate_value(0.0, 1.0, existence, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT);
	pump_value = Tween.interpolate_value(0.0, 1.0, pump_value, 1.0, Tween.TRANS_EXPO, Tween.EASE_IN_OUT);
	scaler.scale = Vector3.ONE * (lerpf(0.5, 1.15, existence) + lerpf(0.0, 0.5, pump_value))

var count:float = 0;

func _enter_tree() -> void:
	count = 0;
	_sfx_play.post(self)

func get_origin()->Node3D:
	return self;

func get_target(origin:Node3D)->Node3D:
	var my_pos:Vector3 = origin.global_position;
	var enemies:Array = get_tree().get_nodes_in_group(Game.instance.enemy_positional_node_group_name);
	var bestDist:float = 99999.0;
	var best:Node3D = null;
	for enemy:Node3D in enemies:
		var nextDist := (enemy.global_position - my_pos).length_squared();
		if nextDist < bestDist:
			best = enemy;
			bestDist = nextDist;
	return best;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var origin:Node3D = get_origin();
	var target:Node3D = get_target(origin);
	if target:
		var direction:Vector3 = target.global_position - origin.global_position;
		var acceleration:Vector3 = direction * acceleration_multiplier;
		speed += acceleration * delta;
	speed -= speed_reduce * speed * delta;
	speed.y = 0;
	if speed.length() > speed_max:
		speed = speed.normalized() * speed_max;
	position += speed * speed_multiplier * delta + LevelCameraController.instance.last_physics_step_movement;

	count += delta;
	existence_percentage = 1.0 - (count / seconds_total)
	if count > seconds_total:
		vanish();

	if out_of_screen_count > 0.0:
		out_of_screen_count -= delta;
		if out_of_screen_count <= 0.0:
			vanish();

func vanish()->void:
	_sfx_stop.post(self)
	queue_free();

func pump():
	pump_value = 1.0;
	create_tween().tween_property(self, "pump_value", 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART);

func _on_damage_area_on_damaged() -> void:
	count += each_damage_take_seconds;

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	out_of_screen_count = 0.0;

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	out_of_screen_count = time_out_of_screen;

func _on_damage_area_on_damaged_data(data:Health.DamageData, victim:Node3D) -> void:
	VFX_Utils.instantiate_vfx_set_for_damage(data, victim.global_position, vfx_hit);
