class_name Boss_Ivo_Pillar extends Node3D

static var pillars_in_sight:Array[Boss_Ivo_Pillar];
@onready var high_contrast: AccessibilityHighContrastObject = $Node3DShaker/rock_pillar/AccessibilityHighContrastObject

@export var radius:float = 1;

@onready var damage_area: DamageArea = $DamageArea
@onready var vulnerable_area: Area3D = $VulnerableArea

@onready var generic_tumbler: GenericTumbler = $GenericTumbler
@onready var spawn_area: SpawnArea = $SpawnArea
@onready var node_3d_shaker: Node3DShaker = $Node3DShaker

@export var sound_fall:WwiseEvent;

func _ready() -> void:
	set_attacking(false);

static func throw_one_pillar(duration:float, func_when:Callable = Callable()):
	pillars_in_sight.sort_custom(func(pillar1:Boss_Ivo_Pillar, pillar2:Boss_Ivo_Pillar):
		return pillar1.global_position.z < pillar2.global_position.z;
		);
	if pillars_in_sight.front() != null:
		pillars_in_sight.front().attack(duration);
		if func_when.is_valid():
			func_when.call();
	else:
		LogUtils.log_warning("eita sem pilastra")
	
func _fall(value:float, destination_up:Vector3):
	basis = Basis(Quaternion(Vector3.UP, Vector3.UP.slerp(destination_up, value)));
	
func set_attacking(attacking:bool):
	if high_contrast and attacking:
		high_contrast.change_group(&"danger");
	vulnerable_area.monitorable = !attacking;
	vulnerable_area.monitoring = !attacking;
	damage_area.monitorable = attacking;
	damage_area.monitoring = attacking;
	
func attack(duration:float):
	set_attacking(true);
	
	generic_tumbler.deactivate();
	pillars_in_sight.erase(self);
	shake(1.0, duration * 0.5);
	var destination_up:Vector3 = Vector3(
		-10.0 * signf(global_position.x),
		0,
		2
	);
	var t := create_tween();
	t.tween_callback(func():
		sound_fall.post(self);
		);
	t.tween_method(_fall.bind(destination_up), 0.0, 0.5, duration * 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC);
	t.tween_method(_fall.bind(destination_up), 0.5, 1.0, duration * 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);
	pass;


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	pillars_in_sight.append(self);


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	pillars_in_sight.erase(self);

var shake_t:Tween;
func shake(force:float, duration:float):
	if shake_t and shake_t.is_valid():
		shake_t.kill();
	node_3d_shaker.shake_amplitude_ratio = force;
	shake_t = node_3d_shaker.create_tween()
	shake_t.tween_property(node_3d_shaker, "shake_amplitude_ratio", 0.0, duration)

var hp_cumulative:float = 0.0;
func _on_health_hit(damage: Health.DamageData, health: Health) -> void:
	shake(damage.amount * 0.25, 0.25);
	
	hp_cumulative += damage.amount;
	var amount_per_explosion:float = 0.25;
	while hp_cumulative > amount_per_explosion:
		hp_cumulative -= amount_per_explosion;
		spawn_area.spawn_multiple(1);
