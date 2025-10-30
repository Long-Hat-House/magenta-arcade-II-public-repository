class_name GenericExploder extends Node3D

@export var explosion_VFX:PackedScene;
### Use the suffix _* on child nodes, where * is the index of the vfx you want.
@export var extra_vfx:Array[PackedScene];
@export var places_to_explode:Array[Node3D];
@export var include_self:bool;
@export var add_all_children_as_places:bool;
@export var position_offset_all:Vector3;
@export var position_offset_random:float = 0.05;
@export var health_on_die_explode:Health;
@export var pre_time_exploding:float = 0.2;
var health_now:Health;

@export var extra_explosions:Array[GenericExploder];

signal exploded;


func _ready() -> void:
	if health_on_die_explode:
		assign_health(health_on_die_explode);


func assign_health(new_health:Health):
	if new_health != health_now:
		if health_now != null:
			health_now.dead.disconnect(on_health_dead);
		health_now = new_health;
		if health_now != null:
			health_now.dead.connect(on_health_dead);



func on_health_dead(health:Health):
	explode();


func explode():
	for explosion in extra_explosions:
		if explosion and explosion != self and is_instance_valid(explosion):
			explosion.explode();


	var explosions:Array[Node3D] = []
	for child:Node3D in get_children():
		explosions.push_back(child);
	if include_self:
		explosions.push_back(self);
	explosions.shuffle();

	var len:int = explosions.size();
	var t := get_tree().create_tween();
	var range1:float = 0.25;
	var range2:float = 0.75;

	var time_left:float = pre_time_exploding;
	var len_beginning:int = len * range1;
	var time_left_each:float = time_left / len_beginning;
	var times:Array[float] = [];
	times.resize(len_beginning);
	if len_beginning > 2:
		for i:int in range(0, len_beginning, 2):
			var rand_value = randf_range(0, time_left_each);
			times[i] = time_left_each - rand_value;
			if i+1 < len_beginning:
				times[i+1] = time_left_each + rand_value;
			print("INST CREATE %s %s" % [i, i + 1]);
		for i:int in range(0, len_beginning):
			var trf := explosions[i].global_transform.orthonormalized().translated(offset_pos());
			t.tween_callback(InstantiateUtils.InstantiateTransform3D.bind(pick_vfx(explosions[i].name), trf));
			t.tween_interval(times[i]);
			t.tween_callback(func(): print("%s INST" % times[i]));
	for i:int in range(len_beginning, len * range2):
		var trf := explosions[i].global_transform.orthonormalized().translated(offset_pos());
		t.tween_callback(InstantiateUtils.InstantiateTransform3D.bind(pick_vfx(explosions[i].name), trf));
	t.tween_callback(func():
		exploded.emit();
		)
	for i:int in range(len * range2, len):
		var trf := explosions[i].global_transform.orthonormalized().translated(offset_pos());
		t.tween_interval(randf_range(0.01,0.025));
		t.tween_callback(InstantiateUtils.InstantiateTransform3D.bind(pick_vfx(explosions[i].name), trf));

func offset_pos()->Vector3:
	return position_offset_all + VectorUtils.rand_vector3_range(-position_offset_random, position_offset_random);

func pick_vfx(where_name:String)->PackedScene:
	var index:int = -1;
	var vfx_scene:PackedScene = explosion_VFX;
	if not extra_vfx.is_empty():
		var has_:int = where_name.find("_", 1);
		if has_>0:
			index = int(where_name.substr(has_ + 1));
			vfx_scene = extra_vfx[index];
	return vfx_scene;
