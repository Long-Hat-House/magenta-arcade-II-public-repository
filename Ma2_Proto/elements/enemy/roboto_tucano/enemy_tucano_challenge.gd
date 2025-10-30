class_name AI_Tucano_Challenge extends AI_Tucano

@onready var health: Health = $Health
@onready var graphic: Graphic_Tucano = $roboto_tucano_graphic

var in_challenge:bool;

var screen_0:Vector3;
var curr_position:float;
@export var pos_increase_ps_base:float = 0.5;
@export var pos_increase_ps_accel:float = 0.1;
@export var pos_damage:float = 0.5;
@export var pos_damage_based_on_position:float = 0.1;
@export var accel_damage:float = 0.1;
@export var max_accel_count_damage:float = 1.25;
@export var position_lose:float = 9.5;
@export var position_min:float = -4;
@export var increase_speed_on_lose:float = 10;

var tween_added_position:Vector3;
var _old_tween_added_position:Vector3;

var locked:bool;

var not_damaged_count:float;

signal lost;
signal killed;

func _ready() -> void:
	super._ready();

func get_current_speed()->float:
	return 0;

func _physics_process(delta: float) -> void:
	if in_challenge:
		curr_position += (pos_increase_ps_base + not_damaged_count * pos_increase_ps_accel) * delta;
		not_damaged_count += delta;

		if curr_position > position_lose:
			stop_challenge();
		elif curr_position < position_min:
			curr_position = position_min;

		var target_pos:Vector3 = get_cam_pos() + screen_0 + Vector3.FORWARD * curr_position;
		move_and_damage(target_pos - global_position);
	else:
		var dist:Vector3 = tween_added_position - _old_tween_added_position;
		if locked: dist += LevelCameraController.instance.last_physics_step_movement
		move(dist);
		_old_tween_added_position = tween_added_position;

func _process(delta: float) -> void:
	if in_challenge:
		graphic.set_speed_scale(remap(curr_position, position_min, position_lose, 0.5, 2.5))

func lock_in_camera()->void:
	locked = true;

func get_cam_pos()->Vector3:
	return LevelCameraController.instance.global_position;

func start_challenge()->void:
	in_challenge = true;
	screen_0 = global_position - get_cam_pos();
	health.release_min_health();

func stop_challenge()->void:
	pos_increase_ps_base += increase_speed_on_lose;
	lost.emit();

func _on_health_hit(damage:Health.DamageData, health: Health) -> void:
	if in_challenge:
		curr_position -= pos_damage * damage.amount +\
				pos_damage_based_on_position * damage.amount * curr_position;
		not_damaged_count -= accel_damage * damage.amount;
		if not_damaged_count > max_accel_count_damage:
			not_damaged_count = max_accel_count_damage;
		elif not_damaged_count < 0:
			not_damaged_count *= -1;

func _on_health_dead(health: Health) -> void:
	super._on_health_dead(health);
	killed.emit();
