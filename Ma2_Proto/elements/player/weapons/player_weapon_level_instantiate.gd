class_name PlayerWeaponLevel_Instantiate extends PlayerWeaponLevel

@export var projectile:PackedScene;
var delayBetweenProjectiles:float;
@export var delayBetweenProjectilesContainsName:String = "";
@export var instruction:String = "Add instantiate positions as children. If it ends with _N it will use [N]th projectile of the extra projectiles array. If there's not children, it will instantiate one in the center."
@export var custom_delay_between_projectiles:float = 0;
@export var force_height:bool = false;
@export var forced_height:float = 0.5;
@export var random_offset:Vector3;
@export var random_offset_each_shot:Vector3;

@export var get_projectile_method:StringName = &"get_projectile"
@export var instantiated_here_method:StringName = &"instantiated_here"


@export_group("Circular Copy")
@export var circular_amount:int = 1;
var angles:Array[float] = []

signal instantiated(proj:Node3D);

var should_await_array:Array[bool];

func _ready():
	should_await_array = [];
	for child in get_children():
		var pos:Node3D = child as Node3D;
		if pos:
			if not delayBetweenProjectilesContainsName.is_empty():
				should_await_array.push_back(pos.name.contains(delayBetweenProjectilesContainsName));
			else:
				should_await_array.push_back(false);

	if not should_await_array.is_empty():
		var count:int = should_await_array.count(true);
		if count > 0:
			if custom_delay_between_projectiles != 0:
				delayBetweenProjectiles = custom_delay_between_projectiles;
			else:
				delayBetweenProjectiles = self.holdInterval / (count + 1);
			#print("[INTERVAL] %s / %s = %s" % [self.holdInterval, (count + 1), delayBetweenProjectiles]);
		else:
			delayBetweenProjectiles = 0.0;

	#print("[WEAPON LEVEL] Initiated with delay %s  for %s (%s)" % [delayBetweenProjectiles, name, owner.name]);

	var multiplier:float = PI * 2.0 / circular_amount;
	angles.resize(circular_amount);
	for index:int in range(circular_amount):
		angles[index] = index * multiplier;

func _shoot(from:Player.TouchData, advanced_time:float)->void:
	if not projectile:
		return;

	for angle in angles:
		shoot_angle(from, angle, advanced_time);

func shoot_angle(from:Player.TouchData, angle:float, advanced_time:float):
	var angle_rot:Vector3 = Vector3.UP * angle;
	if get_child_count() > 0:
		var child_index:int = 0;
		var all_offset:Vector3 = VectorUtils.rand_vector3_range_vector(random_offset);
		for child in get_children():
			var pos:Node3D = child as Node3D;
			if delayBetweenProjectiles > 0:
				if should_await_array[child_index]:
					#print("[WEAPON LEVEL] Wait for %s" % delayBetweenProjectiles);
					if advanced_time > delayBetweenProjectiles:
						advanced_time = advanced_time - delayBetweenProjectiles;
					else:
						#print("[WEAPON LEVEL] Waiting for %s - %s = %s" % [delayBetweenProjectiles, advanced_time, delayBetweenProjectiles - advanced_time]);
						await get_tree().create_timer(delayBetweenProjectiles - advanced_time).timeout;
						advanced_time = 0;
						
					if not is_instance_valid(from.instance) or from.already_left():
						break;
				child_index += 1;
			if pos:
				var ipos:Vector3 = from.instance.global_position + from.instance.instantiateOffset + pos.position;
				ipos += VectorUtils.rand_vector3_range_vector(random_offset_each_shot) + random_offset;
				if force_height:
					ipos.y = forced_height;
				var irot:Vector3 = pos.rotation + angle_rot;
				var used_projectile:PackedScene = projectile;
				if pos.has_method(get_projectile_method):
					used_projectile = pos.call(get_projectile_method);
				var proj = instantiate_projectile(used_projectile, ipos, irot, advanced_time);
				if pos.has_method(instantiated_here_method):
					pos.call(instantiated_here_method, proj);
	else:
		instantiate_projectile(projectile, from.instance.global_position + from.instance.instantiateOffset, self.rotation + angle_rot, advanced_time);

func instantiate_projectile(proj:PackedScene, pos:Vector3, rot:Vector3, advanced_time:float) -> Node3D:
	var instance := InstantiateUtils.Instantiate(proj, LevelManager.get_topmost_node(), true);
	instance.global_position = pos;
	instance.rotation = rot;
	#print("[WEAPON LEVEL] instantiated %s on %s" % [instance, Engine.get_process_frames()]);
	instantiated.emit(instance);
	if advanced_time > 0:
		instance.walk(advanced_time);
	return instance;
