class_name Player_MagicMissileManager extends Node

@onready var player: Player = $".."

@export var magic_missile_scene:PackedScene;
@export var random_distance_range:float = 2;


func _ready() -> void:
	player.use_tap.connect(_just_tapped);
	
func _just_tapped(token:PlayerToken):
	var amount:int = player.currentState.tap_missile_level;
	if amount > 0:
		shoot(token.global_position, amount);

func shoot(where:Vector3, amount:int):
	var enemies:Array = get_tree().get_nodes_in_group(&"enemy_position");
	
	enemies.sort_custom(func sort_function(a:Node3D, b:Node3D):
		if b.is_queued_for_deletion() and !a.is_queued_for_deletion(): return a;
		if a.is_queued_for_deletion() and !b.is_queued_for_deletion(): return b;
		
		var dist_a:float = (a.global_position - where).length();
		var dist_b:float = (b.global_position - where).length();
		dist_a += randf_range(-0.5, 0.5) * random_distance_range;
		dist_b += randf_range(-0.5, 0.5) * random_distance_range;
		if dist_a > dist_b:
			return a;
		else:
			return b;
		)
		
	shoot_to(where, enemies.slice(0, amount));
		
func shoot_to(where:Vector3, enemies:Array):
	for enemy:Node3D in enemies:
		var shot:Player_Projectile_MagicMissile = InstantiateUtils.InstantiatePositionRotation(magic_missile_scene, where, Vector3.FORWARD);
		shot.set_target(enemy);
