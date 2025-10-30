class_name Player_Projectile_MagicMissile extends Area3D

@export var duration:float = 2;
@export var height:float = 0.5;
@export var parabola_height:float = 1.25;
@export var ease_part:float = 0.5;
@export var separation_duration_multiplier:float = 0.2;
@export var trans_first:Tween.TransitionType = Tween.TRANS_QUART;
@export var trans_second:Tween.TransitionType = Tween.TRANS_SINE;
@export var damage:float = 0.5;
@export var hit_vfx:PackedScene;


@onready var visibility: Node3D = $Node3D

var tween:Tween;
var dead:bool;

func _ready() -> void:
	self.area_entered.connect(_on_area_entered);
	self.body_entered.connect(_on_body_entered);

func set_target(target:Node3D):
	var original_place:Transform3D = self.global_transform;
	var original_target:Transform3D = target.global_transform;
	
	var advance_method = func advance_method(value:float):
		var target_transform:Transform3D;
		if is_instance_valid(target):
			target_transform = target.global_transform;
		else:
			target_transform = original_target;
		var distance_now := target_transform.origin - global_position;
		distance_now.y *= 0.5;
		var distance_origin := target_transform.origin - original_place.origin;
		var new_basis  := Basis.looking_at(distance_now.normalized(), Vector3.UP, true);
		var parabola_direction:Vector3 = distance_origin.rotated(Vector3.UP, clampf(distance_origin.x, -1.0, 1.0) * PI * 0.5);
		var parabola:Vector3 = (parabola_direction.normalized() + Vector3.UP) * sin(value * PI) * parabola_height;
		var where:Vector3 = original_place.origin.lerp(target_transform.origin, value) + clampf(value * 8.0, 0.0, 1.0) * height * Vector3.UP;
		global_transform = Transform3D(new_basis, where + parabola);
		
	if tween and tween.is_valid():
		tween.kill();
	tween = create_tween();
	tween.tween_method(advance_method, 0.0, ease_part, duration * separation_duration_multiplier)\
			.set_ease(Tween.EASE_OUT).set_trans(trans_first);
	tween.tween_method(advance_method, ease_part, 1.0, duration * (1.0 - separation_duration_multiplier))\
			.set_ease(Tween.EASE_IN).set_trans(trans_second);
	tween.tween_callback(explode);
		
func _on_area_entered(area:Area3D):
	if try_damage(area):
		explode();
	
func _on_body_entered(body:Node3D):
	try_damage(body);
	explode();
	
func _enter_tree() -> void:
	if !is_node_ready():
		await ready;
	visibility.show();
	dead = false;
	#trail.emitting = true;
	
	
func try_damage(node:Node)->bool:
	var dd:Health.DamageData = Health.DamageData.new(damage, self, true, true);
	return Health.Damage(node, dd);
	
func explode():
	if dead:
		return;
		
	if hit_vfx:
		InstantiateUtils.InstantiateInTree(hit_vfx, self);
	visibility.hide();
	dead = true;
	#trail.emitting = false;
	ObjectPool.repool(self);
	
