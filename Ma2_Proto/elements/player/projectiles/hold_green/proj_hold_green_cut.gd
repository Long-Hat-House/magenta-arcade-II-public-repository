extends Node3D

@onready var scaler: Node3D = $"Damage Area/Scaler"
@onready var mesh: MeshInstance3D = $"Damage Area/Scaler/MeshInstance3D"
@onready var leaf_particle: GPUParticles3D = $"Damage Area/Scaler/LeafParticle"
@export var duration_in:float = 0.05;
@export var duration_out:float = 0.5;
@export var max_range:float = 10;
@export var where:Game.Target_Style;
@onready var damage: DamageArea = $"Damage Area"
@onready var max_range_sqrd:float = max_range * max_range;

@onready var random_angle_max:float = deg_to_rad(8);

func _enter_tree() -> void:
	if not is_node_ready():
		await ready;
	damage.enabled = false;

	scaler.scale.z = 0.01;
	mesh.set_instance_shader_parameter("Cutoff", 0.0);

	await get_tree().physics_frame;
	var dir:Vector3 = get_direction();
	#print("[HOLD GREEN HIT] Got direction %s length %s for the hit %s. (Max range is %s)" % [dir, dir.length_squared(), name, max_range_sqrd]);
	dir = dir.rotated(Vector3.UP, randf_range(-1, 1) * random_angle_max);
	global_basis = Basis.looking_at(dir, Vector3.UP, true);
	await get_tree().physics_frame;

	damage.enable_and_damage();
	var t := create_tween();
	t.set_parallel();
	t.tween_property(scaler, "scale:z", 1.0, duration_in).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	t.tween_property(mesh, "instance_shader_parameters/Cutoff", 0.01, duration_in * 0.05);
	t.tween_callback(func():
		leaf_particle.emitting = true;
		#damage.enabled = false;
		)
	t.tween_property(mesh, "instance_shader_parameters/Cutoff", 1.0, duration_out + duration_in * 0.25).set_delay(duration_in * 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	await t.finished;
	ObjectPool.repool(self);

func get_direction()->Vector3:
	if Game.instance:
		var direction:Vector3 = Game.instance.get_best_direction_to(self, Game.instance.enemy_positional_node_group_name, where);
		if not direction.is_zero_approx() and direction.length_squared() < max_range_sqrd:
			return direction;
	return Vector3.FORWARD;
