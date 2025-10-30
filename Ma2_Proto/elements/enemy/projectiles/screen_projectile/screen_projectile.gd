class_name ScreenProjectile extends Node3D

static var incoming_projectile:ScreenProjectile

@export var lerp_between_two_curves:Curve;
@export var scale_over_time:Curve;
@export var ease:Curve;

@export var total_projectile_time:float = 1;
@export var amount_basis_is_translations:Curve;
@export var random_in_screen_radius:float = 20;

@export var _sfx_impact:WwiseEvent

@onready var projectile: Node3D = $TheProjectile
@onready var path_out: Path3D = $"Path3D OUT CANNON"
@onready var path_in: Path3D = $"Path3D IN CAMERA"

signal finished;
signal progress_eased(progress:float);
signal progress_raw(progress:float);
var did_finish:bool = false;

var count:float;
var in_distance:float;
var out_distance:float;
var v_half_size:Vector2;
var old_pos:Vector3;
var random_screen:Vector2;

func _enter_tree() -> void:
	if is_instance_valid(incoming_projectile):
		queue_free()
	else:
		incoming_projectile = self

	if not is_node_ready():
		await ready;
	count = 0;
	in_distance = path_in.curve.get_baked_length();
	out_distance = path_out.curve.get_baked_length();
	v_half_size = Vector2(get_viewport().size.x * 0.5, get_viewport().size.y * 0.57)
	var random_angle:float = randf() * 2 * PI;
	random_screen = Vector2(sin(random_angle), cos(random_angle)) * randf() * random_in_screen_radius;
	did_finish = false;

func _process(delta: float) -> void:
	count += delta;

	var cam:Camera3D = LevelCameraController.main_camera;
	var v_size = get_viewport().size * 0.5;

	var cam_tr:Transform3D = Transform3D(cam.basis, cam.project_position(v_half_size + random_screen, cam.near + 0.5))
	path_in.global_transform = cam_tr;
	path_out.position += LevelCameraController.instance.last_frame_movement; ##test

	if count > total_projectile_time:
		finish();
	else:
		var percentage_sampler:float = count / total_projectile_time;
		var tr:Transform3D = sample(percentage_sampler);
		#var target_vec:Vector3 = tr.origin - old_pos;
		#var look_at:Transform3D;
		#if target_vec.is_zero_approx():
			#look_at = Transform3D(Basis.IDENTITY, tr.origin);
		#else:
			#look_at = Transform3D(Basis.looking_at(tr.origin - old_pos, tr.basis.y, true), tr.origin);
		#print("lerp(%s, %s, %s) = %s" % [tr.basis, look_at, 0.01, tr.basis.slerp(look_at, 0.01)]);
		#tr = tr.interpolate_with(look_at, amount_basis_is_translations.sample(percentage_sampler));
		projectile.scale = Vector3.ONE * scale_over_time.sample(percentage_sampler)
		tr.basis.z *= -1;
		projectile.global_transform = tr;
		old_pos = tr.origin;

func finish():
	if not did_finish:
		var player = Player.instance
		did_finish = true;
		player.damage(1, projectile.global_position);
		finished.emit();
		_sfx_impact.post(player)

func sample(percentage_sampler:float)->Transform3D:
	var percentage:float = ease.sample(percentage_sampler);
	progress_raw.emit(percentage_sampler);
	progress_eased.emit(percentage);
	var pin:Transform3D = path_in.global_transform * path_in.curve.sample_baked_with_rotation(percentage * in_distance);
	var pout:Transform3D = path_out.global_transform * path_out.curve.sample_baked_with_rotation(percentage * out_distance);

	var t := pout.interpolate_with(pin, lerp_between_two_curves.sample(percentage));
	#t.basis.rotated(Vector3.RIGHT, PI / 2);
	return t;


func _on_projectile_kill_proxy_killed_projectile() -> void:
	if not did_finish:
		queue_free();
