class_name Enemy_LaserArea extends Area3D

@onready var laserArea:Area3D = self;
@onready var lightNode: Node3D = $LightNode

@export var laser_animation:AnimationTree
@export var amountDamage:int = 3;
@export var hit_time:float = 0.25;
@export var scores:bool = false;
@export var laser_shake:CameraShakeData;
@export var no_light:bool;

@onready var sfx_pre: AkEvent3D = $"SFX Laser Pre"
@onready var sfx_loop: AkEvent3DLoop = $"SFX Laser Loop"

var count:float;

signal laser_hit(body:Node3D);
signal prepare;
signal started_laser;
signal ended_laser;

func _ready():
	laser_animation.active = true
	lightNode.visible = !no_light;
	visible = false

func pre_laser():
	visible = true
	laser_animation["parameters/conditions/stop"] = false
	laser_animation["parameters/conditions/start"] = false

	laser_animation["parameters/conditions/prepare"] = true

	sfx_pre.post_event();
	prepare.emit();

func start_laser():
	visible = true
	laser_animation["parameters/conditions/stop"] = false
	laser_animation["parameters/conditions/prepare"] = false

	laser_animation["parameters/conditions/start"] = true
	damage_current_bodies();

	if laser_shake:
		laser_shake.screen_shake();

	sfx_loop.start_loop();
	started_laser.emit();

func stop_laser():
	laser_animation["parameters/conditions/start"] = false
	laser_animation["parameters/conditions/prepare"] = false

	laser_animation["parameters/conditions/stop"] = true

	sfx_loop.stop_loop();

	ended_laser.emit();

func is_active() -> bool:
	return laser_animation["parameters/conditions/start"] || laser_animation["parameters/conditions/prepare"]

var current_bodies:Array[Node3D] = [];

func damage_current_bodies():
	if not current_bodies.is_empty():
		var damage:Health.DamageData = Health.DamageData.new(amountDamage, self)
		damage.scores = scores;
		damage.immunityTime = hit_time * 0.9;
		for body in current_bodies:
			if body and is_instance_valid(body):
				laser_hit.emit(body);
				Health.Damage(body, damage);

func start_damaging_body(body:Node3D):
	current_bodies.push_back(body);
	damage_current_bodies();

func stop_damaging_body(body:Node3D):
	var remove_body = func remove_bdy_deferred():
		current_bodies.erase(body);
	remove_body.call_deferred();


func _on_body_entered(body):
	start_damaging_body(body);

func _on_body_exited(body):
	stop_damaging_body(body);

func _on_area_entered(area: Area3D) -> void:
	start_damaging_body(area);

func _on_area_exited(area: Area3D) -> void:
	stop_damaging_body(area);

func _physics_process(delta: float) -> void:
	if is_active():
		count += delta;
		while count > hit_time:
			count -= hit_time;
			damage_current_bodies();
