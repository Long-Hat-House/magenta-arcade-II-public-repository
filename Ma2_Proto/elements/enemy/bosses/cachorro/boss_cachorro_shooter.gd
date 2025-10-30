class_name Boss_Shooter extends LHH3D

@export var projectiles:Array[PackedScene];
@export var chances:Array[int];
@export var range_angle:float;
var range_angle_rad:float;

signal instantiated_projectile(projectile:Node3D);
signal instantiated_projectile_scene(projectile:Node3D, scene:PackedScene);

func _ready() -> void:
	range_angle_rad = deg_to_rad(range_angle);
	
func shoot(intensity:int):
	_instantiate_projectile(_get_projectile(intensity), _get_random_angle());
	
func shoot_angle(intensity:int, angle_rad:float):
	_instantiate_projectile(_get_projectile(intensity), angle_rad);
	
func shoot_random():
	_instantiate_projectile(_get_random_projectile(), _get_random_angle());
	
func _get_random_angle()->float:
	return randf_range(-range_angle_rad, range_angle_rad) * 0.5;
	
func _instantiate_projectile(scene:PackedScene, angle:float):
	var proj = 	InstantiateUtils.InstantiateInTree(scene, self, Vector3.ZERO, false, true);
	proj.basis = Basis.looking_at((-self.global_basis.z).rotated(Vector3.UP, angle));
	
	instantiated_projectile.emit(proj);
	instantiated_projectile_scene.emit(proj, scene);
	
func _get_random_projectile()->PackedScene:
	var total_chance:int = chances.reduce(func(old:int, new:int): return old + new, 0);
	var random_chance:int = randi_range(0, total_chance);
	var chance:int = 0;
	for i:int in range(chances.size()):
		chance += chances[i];
		if random_chance < chance:
			return projectiles[i];
	return projectiles[0];
	
func _get_projectile(intensity:int)->PackedScene:
	return projectiles[intensity];
