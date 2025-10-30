extends Node3D

const PROJ_TAP_RED_EXPLOSION = preload("res://elements/player/projectiles/tap_red/proj_tap_red_explosion.tscn")

var direction:Vector3;

var to_direction:float;

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

@onready var scaler: Node3D = %Scaler
@export var velocity_none_scale:Vector3 = Vector3.ONE;
@export var velocity_high_scale:Vector3 = Vector3.ONE;

@export var min_velocity:float = -8;
@export var max_velocity:float = 30;
@export var duration_velocity_change:float = 0.75;
@export var camera_multiplier:Vector3 = Vector3(0,0,1);

@export var duration_out_of_screen:float = 2;
var count_off_screen:float = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	direction = get_direction();
	create_tween().tween_method(func(value:float):
		to_direction = value;
		, min_velocity, max_velocity, duration_velocity_change)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);

func _process(delta: float) -> void:
	var lerp:float = clampf(absf(to_direction), 0, max_velocity);
	lerp = inverse_lerp(0, max_velocity, lerp);
	lerp = pow(lerp, 3);
	scaler.scale = velocity_none_scale.lerp(velocity_high_scale, lerp);

func _physics_process(delta: float) -> void:
	var speed:Vector3 = direction * to_direction;
	speed.y = 0;
	position += speed * delta;

	if LevelCameraController.instance:
		position += LevelCameraController.instance.last_physics_step_movement * camera_multiplier;

	if notifier.is_on_screen():
		count_off_screen = move_toward(count_off_screen, 0, delta);
	else:
		count_off_screen += delta;
		if count_off_screen > duration_out_of_screen:
			vanish();

func get_direction()->Vector3:
	return Vector3.FORWARD;

func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	explode();
	vanish();

func _on_area_3d_area_entered(area: Area3D) -> void:
	explode();
	vanish();

func explode():
	InstantiateUtils.InstantiateInSamePlace3D(PROJ_TAP_RED_EXPLOSION, self);

func vanish():
	queue_free();
