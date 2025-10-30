class_name VFX_Utils

const VFX_EXPLOSION = preload("res://elements/vfx/vfx_explosion/vfx_explosion.tscn")
const VFX_BOSS_EXPLOSION = preload("res://elements/vfx/vfx_boss_explosion.tscn")
const VFX_PILLAR_OF_LIGHT = preload("res://elements/vfx/vfx_pillar_of_light/vfx_pillar_of_light.tscn")

const CAMERA_SHAKE_BOSS_DEATH:CameraShakeData = preload("res://systems/screen/camera_shake_boss_death.tres")

const damage_per_vfx:float = 0.5;

static func _get_random_position(region:AABB)->Vector3:
	var size:Vector3 = region.size;
	size.x *= randf(); size.y *= randf(); size.z *= randf();
	return region.position + size;

static func _get_random_position_in_quadrant(region:AABB, x:bool, y:bool, z:bool)->Vector3:
	var size:Vector3 = region.size;
	var sizeQuadrant:Vector3 = region.size * 0.5;
	var positionQuadrant = Vector3(
		1.0 if x else 0.0,
		1.0 if y else 0.0,
		1.0 if z else 0.0,
		) * sizeQuadrant;
	var sizeRandom:Vector3 = Vector3(sizeQuadrant.x * randf(), sizeQuadrant.y * randf(), sizeQuadrant.z * randf());
	#print("getting random position in %s -> %s + %s + %s" % [[x,y,z], region.position, positionQuadrant, sizeQuadrant]);
	return region.position + positionQuadrant + sizeRandom;


static func _get_all_quadrants()->Array:
	var arr:Array = [];
	for x in [true, false]:
		for y in [true, false]:
			for z in [true, false]:
				arr.push_back([x, y, z]);
	return arr;

static func _get_all_quadrants_lock_y(y_lock:bool = true)->Array:
	var arr:Array = [];
	for x in [true, false]:
		for z in [true, false]:
			arr.push_back([x, y_lock, z]);
	return arr;


static func _instantiate(vfx:PackedScene, position:Vector3, rotation:Vector3, where:Node3D, use_object_pool:bool)->Node3D:
	if vfx == null:
		push_warning("[VFX-Utils] trying to make null vfx in '%s'" % where)
		return null;
	else:
		return InstantiateUtils.InstantiatePositionRotation(vfx, position, rotation, where, use_object_pool);


static func instantiate_vfx_set_for_damage(damage:Health.DamageData, position:Vector3, hit_vfx:PackedScene, vfx_hit_radius:float = 0.5):
	var amount_vfx:int = ceili(damage.amount / damage_per_vfx);
	#print("[VFX-Utils] hit for %s damage making %s vfxes [%s]" % [damage.amount, amount_vfx, Engine.get_physics_frames()]);
	for i:int in amount_vfx:
		var randAlteration:Vector3 = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized() * vfx_hit_radius;
		var rot:Vector3 = randf() * Vector3.UP * 360;
		_instantiate(hit_vfx, position + randAlteration, rot, null, true);

static func make_boss_explosion(bossNode:Node, global_aabb:VisualInstance3D)->Tween:
	var tween:Tween = bossNode.create_tween();
	
	var light_node:Node3D = Node3D.new();
	var ak_event:AkEvent3D = AkEvent3D.new();
	tween.tween_callback(func():
		HUD.instance.make_screen_effect(HUD.ScreenEffect.BossDeath);
		CAMERA_SHAKE_BOSS_DEATH.screen_shake();
		AudioManager.post_one_shot_event(AK.EVENTS.PLAY_BOSS_DEATH)
		bossNode.add_child(light_node);
		);
	var vfx_tween:Tween = bossNode.create_tween();
	vfx_tween.set_parallel(true);
	VFX_Utils.make_vfxs_in_region(vfx_tween, [VFX_EXPLOSION], bossNode, global_aabb, 160, HUD.boss_flash_duration - 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_delay(1.0);
	VFX_Utils.make_vfxs_in_region_directional(vfx_tween, [VFX_PILLAR_OF_LIGHT], light_node, global_aabb, 14, HUD.boss_flash_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR);
	tween.tween_subtween(vfx_tween);
	
	tween.tween_callback(func():
		light_node.queue_free();
		)
	tween.tween_interval(HUD.post_boss_flash_duration * 0.75);
	tween.tween_callback(func():
		var aabb:AABB = global_aabb.global_transform * global_aabb.get_aabb();
		InstantiateUtils.InstantiatePositionRotation(VFX_BOSS_EXPLOSION, aabb.get_center());
		)
	await tween.finished;
	return tween;


static func make_vfxs_in_region(
			tween:Tween,
			vfxs:Array[PackedScene],
			parent:Node3D,
			region_global:VisualInstance3D,
			explosions:int,
			duration:float,
			object_pool:bool = true,
			enforce_normalized_basis:bool = true,
			on_each_instance:Callable = Callable())->MethodTweener:

	if duration == 0:
		while explosions > 0:
			explosions -= 1;
			var pos:Vector3 = _get_random_position(region_global.global_transform * region_global.get_aabb());
			var inst:Node3D = _instantiate(vfxs.pick_random(), pos, Vector3.ZERO, parent, object_pool);
			if enforce_normalized_basis:
				inst.global_basis = inst.global_basis.orthonormalized();
			if on_each_instance.is_valid():
				on_each_instance.call(inst);
		return null;
	else:
		var happened:Array[int] = [0];
		return tween.tween_method(func set_value_explosion(v:float):
			var next:float = float(happened[0])/explosions;
			var region:AABB = region_global.global_transform * region_global.get_aabb();
			while v > next:
				next = float(happened[0])/explosions;
				var pos:Vector3 = _get_random_position(region);
				var inst:Node3D = _instantiate(vfxs.pick_random(), pos, Vector3.ZERO, parent, object_pool);
				if enforce_normalized_basis:
					inst.global_basis = inst.global_basis.orthonormalized();
				if on_each_instance.is_valid():
					on_each_instance.call(inst);
				happened[0] += 1;
			, 0.0, 1.0, duration);


class DirectionalInfo:
	var index:int;
	var quadrants:Array;
	

static func make_vfxs_in_region_directional(
			tween:Tween,
			vfxs:Array[PackedScene],
			where:Node3D,
			region_global:VisualInstance3D,
			explosions:int,
			duration:float)->MethodTweener:

	var info:DirectionalInfo = DirectionalInfo.new();

	info.index = 0;
	info.quadrants = _get_all_quadrants_lock_y();

	return tween.tween_method(func set_value_explosion(v:float):
		var next:float = float(info.index)/explosions;
		var region:AABB = region_global.global_transform * region_global.get_aabb();
		while v > next:
			if info.index % info.quadrants.size() == 0:
				info.quadrants.shuffle();

			var quadrant_array:Array = info.quadrants[info.index % info.quadrants.size()];
			var pos:Vector3 = _get_random_position_in_quadrant(region, quadrant_array[0], quadrant_array[1], quadrant_array[2]);

			var scene:PackedScene = vfxs.pick_random() as PackedScene;
			var node:Node3D = _instantiate(scene, pos, Vector3.ZERO, where, true);

			var z_axis:Vector3 = LevelCameraController.main_camera.global_basis.z;
			var y_axis:Vector3 = Plane(z_axis).project((pos-region.get_center()).normalized());
			var x_axis:Vector3 = -y_axis.cross(z_axis);
			node.global_basis = Basis(x_axis, y_axis, z_axis);

			info.index += 1;
			next = float(info.index)/explosions;
		, 0.0, 1.0, duration);
