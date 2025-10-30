class_name Boss_Hand_Fissure extends LHH3D

@export var part_scene:PackedScene;
@export var total_length:float = 20;
@export var part_length:float = 4;
@export var time_between_min:float = 0.35;
@export var time_between_max:float = 0.7;
@export var angle_max:float;
@export var range_random_length:float = 0.4;


var angle_rad:float;

var pos:Vector3;

static var rachaduras:Array[Boss_Hand_Fissure];
var points:Array[Vector3] = [];

func _enter_tree() -> void:
	rachaduras.append(self);
	
func _exit_tree() -> void:
	points.clear();
	rachaduras.erase(self);

func _ready() -> void:
	angle_rad = deg_to_rad(angle_max);
	
	create_all_fissures();
	
	
func create_all_fissures():
	while total_length > 0:
		total_length -= create_fissure();
		await get_tree().create_timer(randf_range(time_between_min, time_between_max)).timeout;
		
		
func create_fissure()->float:
	var part:Node3D = part_scene.instantiate();
	add_child(part);
	part.position = pos;
	part.tree_exited.connect(_check_children);
	var own_position:Vector3 = global_position + pos;
	var dir_to_go:Vector3 = Vector3.BACK * 100;
	var player_attraction:Vector3 = Player.get_closest_direction(own_position, true, Vector3.BACK * 2.0).normalized() * 50.0
	dir_to_go += player_attraction;
	print("[RACHADURA] Dir to go TOWARDS = %s + %s = %s" % [
		Vector3.BACK * 5,
		player_attraction,
		dir_to_go,
		]);
	for fissure:Boss_Hand_Fissure in rachaduras:
		if fissure != self:
			for point in fissure.points:
				var point_position = fissure.global_position + point;
				var dist:Vector3 = point_position - own_position;
				var repel:Vector3 = -dist.normalized() * 20 / dist.length()
				dir_to_go += repel;
				print("[RACHADURA] Dir to go AVOID += %s (%s) = %s" % [
					repel,
					dist,
					dir_to_go
				]);
	print("[RACHADURA] dir FINAL %s -> %s" % [dir_to_go, dir_to_go.normalized()]);
	part.basis = Basis.looking_at(dir_to_go.normalized().rotated(Vector3.UP, randf_range(-angle_rad, angle_rad) * 0.5), Vector3.UP, true);
	
	var multiplier:float = 1 + randf_range(-range_random_length, range_random_length) * 0.5;
	part.basis.z *= multiplier;
	pos = pos + part.basis.z * part_length;
	points.append(pos);
	return part_length * multiplier;
	
func _check_children():
	if get_child_count() <= 0:
		queue_free();
