extends Node3D

var color:Color:
	get:
		return color;
	set(value):
		color = value;
		mesh.get_active_material(0).set("albedo_color", color);


@onready var mesh: MeshInstance3D = $Scaler/graphic/MeshInstance3D
@onready var graphic: Node3D = $Scaler/graphic
@onready var particles: GPUParticles3D = $Scaler/graphic/GPUParticles3D
@onready var area: Area3D = $Scaler/Area3D
@onready var scaler:Node3D = $Scaler;

var transparent:Color;

@export var time_delay:float = 0.75;
@export var damage:int = 0;
@export var dissipate_when_touched:bool = true;
@export var height:float = 1;

@export_category("Follow Player")
@export var max_velocity:float = 5;
@export var max_acceleration:float = 30;
@export var max_acceleration_done:float = 5;
@export var sensivity_acceleration:float = 0;
@export var time_to_accelerate:float = 10;
var curr_velocity:Vector3;
var curr_acceleration:Vector3;
var curr_delay:float;

var current_tween:Tween;
var quitting:bool = false;

func _ready():
	particles.draw_pass_1.surface_set_material(0, mesh.get_active_material(0));
	curr_delay = time_to_accelerate;
	await get_tree().create_timer(1).timeout;
	
func _physics_process(delta: float) -> void:
	if curr_delay > 0:
		curr_delay -= delta;
	else:
		var dir:Vector3 = Player.get_closest_direction(self.global_position, false, Vector3.ZERO)
		curr_acceleration +=  sensivity_acceleration * delta * dir;
		curr_acceleration = curr_acceleration.limit_length(max_acceleration)
		var accel_add:float = (curr_acceleration * delta).length();
		accel_add = minf(max_acceleration_done, accel_add);
		max_acceleration_done -= accel_add;
		curr_velocity += curr_acceleration.normalized() * accel_add;
		curr_velocity = curr_velocity.limit_length(max_velocity);
	
	position += curr_velocity * delta;

func _enter_tree() -> void:
	quitting = false;
	if not is_node_ready():
		await ready;

	var rotate_tween:Tween = create_tween();
	rotate_tween.tween_method(func(value:float):
		self.basis = Basis.IDENTITY.rotated(Vector3.UP, value);
		,0.0, PI * 1.25, 2.5 + randf() * 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);

	scaler.scale = Vector3.ONE * 0.001;

	current_tween = create_tween();
	current_tween.tween_property(scaler, "scale", Vector3.ONE * remap(randf(), 0.0, 1.0, 1.0, 1.2), 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	current_tween.tween_interval(0.15);
	await current_tween.finished;
	
	current_tween = create_tween();
	current_tween.set_parallel();
	current_tween.tween_property(scaler, "scale", Vector3.ONE * remap(randf(), 0.0, 1.0, 1.75, 2.0), 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	current_tween.tween_property(graphic, "position", Vector3.UP * height, 0.95).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
	await current_tween.finished;

	current_tween = create_tween();
	current_tween.tween_interval(time_delay);
	await current_tween.finished;
	quit();

func quit():
	if not quitting:
		area.queue_free();
		quitting = true;
		if current_tween and current_tween.is_running():
			current_tween.kill();
		var t := create_tween();
		t.tween_property(scaler, "scale", Vector3.ONE * 0.01, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
		await t.finished;
		queue_free();

func _on_area_3d_body_entered(body: Node3D) -> void:
	if damage > 0:
		Health.Damage(body, Health.DamageData.new(damage, self, false));
	if dissipate_when_touched:
		quit();


func _on_health_dead(health: Health) -> void:
	quit();


func _on_projectile_proxy_call_destroy() -> void:
	quit();
