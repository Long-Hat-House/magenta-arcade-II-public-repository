class_name PlayerToken extends CharacterBody3D

const CAMERA_SHAKE_SMALL = preload("res://systems/screen/camera_shake_small.tres")

@export var instantiateOffset:Vector3 = Vector3.UP * 0.5;
@onready var mesh = $"Player Mesh"
@onready var collision = $"Player Collision"
@onready var force_generator_spherical: ForceGenerator_Spherical = %ForceGenerator
@onready var hold_loop: AkEvent3DLoop = $"Hold Loop"
@onready var player_shadow: MeshInstance3D = $"Player Shadow"
@export var extra_projectile_target_scene:PackedScene;

@export_category("Vibration")
@export var vibration_profile:VibrationProcess;
@export var vibration_damaged:VibrationSingle;

@export_category("SFX")
@export var sfx_tap_attempt:AkEvent3D;
@export var sfx_hurt: AkEvent3D

@export_category("Energy")
@export var teleport_height:float = 0.5;
@export var energy_addition:float = 2;
@export var energy_dissipation:float = 0.25;
@export var energy_max:float = 1;

@export_category("Particles")
@export var all_movement_particles:GPUParticles3D
@export var particles_one_shot:GPUParticles3D
@export var trail_particles_ground: GPUParticles3D
@export var trail_particles_water: GPUParticles3D
@export var trail_particles_cloud: CPUParticles3D
@export var trail_vfx_ground:PackedScene;
@export var trail_vfx_water:PackedScene;
@export var trail_vfx_cloud:PackedScene;
@export var trail_every_second:float = 4;
@export var trail_every_meter:float = 3;
@export var trail_randomness:float = 0.25;
@export var vfx_wind: GPUParticles3D;

@export_category("Debug")
@export var debug_pressables:bool;
@export var debug_pressables_stack:bool;

enum EnergyType
{
	RawTranslation,
	Energy,
	ScreenEnergy
}

enum TerrainType
{
	Ground,
	Unknown,
	Water,
	Cloud,
}

var _current_terrain_type:TerrainType = TerrainType.Ground
var _current_trail_vfx:PackedScene
var trail_count:float

var _energy:Vector3;
var _screen_energy:Vector3;

func get_energy(type:EnergyType = EnergyType.ScreenEnergy)->Vector3:
	match type:
		EnergyType.RawTranslation:
			return _current_velocity;
		EnergyType.Energy:
			return _energy;
		EnergyType.ScreenEnergy:
			return _screen_energy;
	return _energy;

var timeExisting:float = 0;
var currentPresseable:Pressable;
var _old_position:Vector3;
var _old_position_physics:Vector3;
var _current_velocity:Vector3;

var last_frame_displacement:Vector3;
var last_physics_tick_displacement:Vector3;

##A value for hold weapons to use
var holdValue:float = 0;

var ending:bool = false;
var first_time:bool;

var current_shadow_tween:Tween;
var shadow_now:float = 0:
	get:
		return shadow_now;
	set(value):
		shadow_now = value;
		player_shadow.basis = Basis.IDENTITY.scaled(Vector3.ONE * value);
var shadow_max_velocity:float = 4;

signal energy_process(energy:Vector3);
signal energy_screen_process(energy:Vector3);
signal velocity_process(velocity:Vector3);
signal translation_process(translation:Vector3);
signal translation_uncamera_process(translation:Vector3);

signal pressed;
signal released;
signal released_tap;

func _ready():
	timeExisting = 0;
	_old_position = global_position;
	_old_position_physics = global_position;
	ending = false;
	_show_shadow();

func _enter_tree() -> void:
	first_time = true

func _show_shadow():
	if current_shadow_tween and current_shadow_tween.is_running():
		current_shadow_tween.kill();
	current_shadow_tween = create_tween();
	current_shadow_tween.tween_property(self, "shadow_now", 1.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);

func _hide_shadow():
	if current_shadow_tween and current_shadow_tween.is_running():
		current_shadow_tween.kill();
	current_shadow_tween = create_tween();
	current_shadow_tween.tween_property(self, "shadow_now", 0.1, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);

func tap_feedback():
	sfx_tap_attempt.post_event();
	CAMERA_SHAKE_SMALL.screen_shake()

func has_presseable():
	return currentPresseable != null;

func is_in_game():
	return not ending;

func get_last_frame_displacement(physics:bool = true, camera_independent:bool = true)-> Vector3:
	var disp:Vector3;
	if physics:
		disp = last_physics_tick_displacement;
		if camera_independent:
			disp -= LevelCameraController.instance.last_physics_step_movement;
	else:
		disp = last_frame_displacement;
		if camera_independent:
			disp -= LevelCameraController.instance.last_frame_movement;
	return disp;


func get_current_terrain_type() -> TerrainType:
	return _current_terrain_type

func get_current_terrain_type_name() -> StringName:
	return TerrainType.keys()[_current_terrain_type]

func _update_terrain_type():
	if has_presseable():
		_current_terrain_type = TerrainType.Unknown
	else:
		var k_col := _process_touch_place()
		if !k_col || k_col.get_collision_count() <= 0:
			_current_terrain_type = TerrainType.Ground
		else:
			_current_terrain_type = TerrainType.Ground
			for index:int in range(k_col.get_collision_count()):
				var col:CollisionObject3D = k_col.get_collider();
				if col.get_collision_layer_value(9):
					var col_name:String = col.name.to_lower()
					if col_name.contains("cloud"):
						_current_terrain_type = TerrainType.Cloud
						break
					elif col_name.contains("ground"):
						_current_terrain_type = TerrainType.Ground
						break
					elif col_name.contains("water"):
						_current_terrain_type = TerrainType.Water
						break

	match _current_terrain_type:
		TerrainType.Ground:
			trail_particles_ground.visible = true
			trail_particles_water.visible = false
			trail_particles_cloud.visible = false
			_current_trail_vfx = trail_vfx_ground
		TerrainType.Water:
			trail_particles_ground.visible = false
			trail_particles_water.visible = true
			trail_particles_cloud.visible = false
			_current_trail_vfx = trail_vfx_water
		TerrainType.Cloud:
			trail_particles_ground.visible = false
			trail_particles_water.visible = false
			trail_particles_cloud.visible = true
			_current_trail_vfx = trail_vfx_cloud
		_:
			trail_particles_ground.visible = false
			trail_particles_water.visible = false
			trail_particles_cloud.visible = false
			_current_trail_vfx = null

func _physics_process(delta: float) -> void:
	var pos:Vector3 = global_position;
	last_physics_tick_displacement = pos - _old_position_physics;
	_old_position_physics = pos;

func _process(delta:float):
	if ending: return;

	if first_time:
		_old_position = global_position;
		first_time = false

	_update_terrain_type()

	timeExisting += delta;

	var translation:Vector3 = global_position - _old_position;
	if absf(translation.y) > teleport_height:
		## it was a teleport! No translation.
		translation = Vector3.ZERO;

	last_frame_displacement = translation;
	_process_translation_and_energy(translation, delta);

	if delta == 0.0: delta = 1.0/60.0;
	var value:float = translation.length() / delta;
	hold_loop.set_parameter(AK.GAME_PARAMETERS.PLR_DRAGSPEED, value);

	_old_position = global_position;

	if vibration_profile:
		vibration_profile.vibration_follow_node_process(self, delta);

	if _current_trail_vfx and absf(_old_position.y) < 0.5:
		trail_count += translation.length() * trail_every_meter;
		trail_count += delta * trail_every_second;

		if trail_count > 1.0:
			var amount:int = floori(trail_count);
			trail_count -= float(amount);

			var trail_translation:Vector3 = -translation;
			trail_translation.y = clampf(trail_translation.y, -0.1, 0.1);
			if amount == 1:
				InstantiateUtils.InstantiateInTree(_current_trail_vfx, self, trail_translation * 0.5 + get_random_trail_offset(trail_translation));
			else:
				for i:int in range(amount):
					var part:float = float(i + 1) / float(amount + 1);
					InstantiateUtils.InstantiateInTree(_current_trail_vfx, self, trail_translation * part + get_random_trail_offset(trail_translation * part))

func get_random_trail_offset(trail_translation:Vector3):
	return Vector3(randf() - 0.5, 0.0, randf() - 0.5) * (trail_randomness + trail_translation.length());

func _process_translation_and_energy(translation:Vector3, delta:float):
	var translation_uncamera = translation;
	if LevelCameraController.instance:
		translation_uncamera -= LevelCameraController.instance.last_frame_movement;

	_current_velocity = translation / delta;

	_energy += translation * energy_addition * delta;
	_energy = _energy.move_toward(Vector3.ZERO, delta * energy_dissipation);
	_energy = _energy.limit_length(energy_max);

	_screen_energy += translation_uncamera * energy_addition * delta;
	_screen_energy = _screen_energy.move_toward(Vector3.ZERO, delta * energy_dissipation);
	_screen_energy = _screen_energy.limit_length(energy_max);

	energy_process.emit(_energy);
	energy_screen_process.emit(_screen_energy);
	velocity_process.emit(_current_velocity);
	translation_process.emit(translation);
	translation_uncamera_process.emit(translation_uncamera);

func _process_touch_place()->KinematicCollision3D:
	return move_and_collide(Vector3.DOWN, true, 0.1, true, 2);

func end_token()->void:
	var arr:Array[Pressable] = _stack_pressables.duplicate();
	for pressable in arr:
		if is_instance_valid(pressable):
			remove_presseable(pressable);

	ending = true;
	_hide_shadow();
	extra_projectile_positions.queue_free();
	collision.queue_free();
	mesh.queue_free();
	force_generator_spherical.queue_free();
	hold_loop.queue_free();
	all_movement_particles.one_shot = true;
	all_movement_particles.emitting = false;
	vfx_wind.emitting = false;
	await get_tree().create_timer(maxf(all_movement_particles.lifetime, vfx_wind.lifetime) + 0.1).timeout;
	self.queue_free();
	pass;

func get_token_velocity()->Vector3:
	return _current_velocity;

func check_for_presseable_process(touch:Player.TouchData, delta:float):
	##do nothing, pressables search for the player themselves
	pass;


var _stack_pressables:Array[Pressable];
func add_presseable(presseable:Pressable) -> void:
	_stack_pressables.push_back(presseable);
	change_presseable(check_pressable());
	presseable.tree_exited.connect(remove_presseable.bind(presseable))
	if debug_pressables:
		print("[PLAYER TOKEN] %s Pressables '%s', current %s. (Added %s)" % [self.name, _stack_pressables, check_pressable(), presseable]);
		if debug_pressables_stack:
			print_stack();

func remove_presseable(presseable:Pressable)-> void:
	_stack_pressables.erase(presseable);
	presseable.tree_exited.disconnect(remove_presseable.bind(presseable));
	change_presseable(check_pressable());
	if debug_pressables:
		print("[PLAYER TOKEN] %s Pressables '%s', current %s. (Removed %s)" % [self.name, _stack_pressables, check_pressable(), presseable]);
		if debug_pressables_stack:
			print_stack();


func check_pressable()->Pressable:
	var pressable:Pressable = null;
	var priority:int = -9999;
	var to_destroy_ids:Array[int] = []
	for i in range(0, _stack_pressables.size()):
		var p:Pressable = _stack_pressables[i]
		if not is_instance_valid(p):
			to_destroy_ids.push_back(i);
			continue;
		if p.pressable_priority >= priority:
			pressable = p;
			priority = p.pressable_priority;
	for id:int in to_destroy_ids:
		_stack_pressables.remove_at(id)
	return pressable;

func change_presseable(presseable:Pressable) -> bool:
	if currentPresseable != presseable:
		var touch:Player.TouchData = Player.instance.find_touch_data_from_token(self);
		if currentPresseable and is_instance_valid(currentPresseable):
			currentPresseable.end_pressing(touch);
		currentPresseable = presseable;
		if presseable:
			presseable.start_pressing(touch);
			if debug_pressables:
				print("[PLAYER TOKEN] Add pressed in lifetime to %s [%s]" % [touch, Engine.get_physics_frames()]);
			if touch:
				touch.pressedInLifetime = true;
		return true;
	else:
		return false;


func _on_player_health_hit(damage:RefCounted, health: Health) -> void:
	sfx_hurt.post_event();

@onready var extra_projectile_positions: ChildrenInCircleMoving = $"Extra Projectile Positions"


func add_extra_projectile_target()->Node3D:
	var inst:Node3D = extra_projectile_target_scene.instantiate();
	extra_projectile_positions.add_child(inst);
	return inst;

func remove_extra_projectile_target():
	extra_projectile_positions.get_child(extra_projectile_positions.get_child_count() - 1).queue_free();

func current_extra_projectile_target_amount()->int:
	return extra_projectile_positions.get_size();

func set_extra_shot_speed(speed_angle:float):
	extra_projectile_positions.velocity_degrees = speed_angle;


var _pressable_entered:bool;
func _on_pressable_feeler_area_entered(area: Area3D) -> void:
	if !_pressable_entered:
		var touch:Player.TouchData = Player.instance.find_touch_data_from_token(self);
		if touch:
			touch.pressedInLifetime = true;
			_pressable_entered = true;
