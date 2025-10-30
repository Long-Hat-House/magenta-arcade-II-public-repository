class_name SimpleVFX extends Node3D

@export var _animated_sprite_3d:AnimatedSprite3D
## Will play an animation named "one_shot" and wait for it to be finished
@export var _animation_player:AnimationPlayer
@export var _animation_name:StringName = &"one_shot";
@export var _cpu_particles_3d:CPUParticles3D
@export var _gpu_particles_3d:GPUParticles3D
@export var visibility_while_animating:Array[Node3D];
@export var visibility_until_particles:Array[Node3D];
@export var jointInstantiates:Array[PackedScene]
@export var animationSpeedScaleRange:float = 0
@export_range(0.0, 1.0) var glued_to_screen:float;
@export var xzRandomRange:float = 0
@export var yRandomRange:float = 0
@export var sound:AkEvent3D
@export var _task:Task

var _animated_sprite_3d_original_speed_scale:float;
var _animation_player_original_speed_scale:float;
var _cpu_particles_3d_original_speed_scale:float;
var _gpu_particles_3d_original_speed_scale:float;

signal done;

var readied:bool;

func _enter_tree():
	if readied:
		startAnim();

func _process(delta: float) -> void:
	position += LevelCameraController.instance.last_frame_movement * glued_to_screen;

func _ready():
	if !_animated_sprite_3d && has_node("Sprite3D"):
		_animated_sprite_3d = $Sprite3D as AnimatedSprite3D;

	if _animated_sprite_3d:
		_animated_sprite_3d_original_speed_scale = _animated_sprite_3d.speed_scale;
	if _animation_player:
		_animation_player_original_speed_scale = _animation_player.speed_scale
	if _cpu_particles_3d:
		_cpu_particles_3d_original_speed_scale = _cpu_particles_3d.speed_scale
	if _gpu_particles_3d:
		_gpu_particles_3d_original_speed_scale = _gpu_particles_3d.speed_scale

	readied = true;
	startAnim();

func startAnim():
	_randomizePosition();
	_randomizeAnimation();
	_joint_instantiates();

	await get_tree().process_frame;
	if !is_instance_valid(self) or get_tree() == null: return

	if sound:
		sound.post_event();

	if _task:
		_task.start_task()

	if _animated_sprite_3d:
		_animated_sprite_3d.play();
	if _animation_player:
		_animation_player.play(_animation_name)
	if _cpu_particles_3d:
		_cpu_particles_3d.emitting = true
		_cpu_particles_3d.restart()
	if _gpu_particles_3d:
		_gpu_particles_3d.emitting = true
		_gpu_particles_3d.restart()

	for vis in visibility_while_animating:
		vis.visible = true;
	for vis in visibility_until_particles:
		vis.visible = true;

	while _animated_sprite_3d && _animated_sprite_3d.is_playing():
		await get_tree().process_frame
		if !is_instance_valid(self): return
	while _animation_player && _animation_player.is_playing():
		await get_tree().process_frame
		if !is_instance_valid(self): return
	for vis in visibility_while_animating:
		vis.visible = false

	while _cpu_particles_3d && _cpu_particles_3d.is_emitting():
		await get_tree().process_frame
		if !is_instance_valid(self): return
	while _gpu_particles_3d && _gpu_particles_3d.is_emitting():
		await get_tree().process_frame
		if !is_instance_valid(self): return
	for vis in visibility_until_particles:
		vis.visible = false

	#print_debug("[SIMPLE VFX] FINISHED")
	done.emit();
	ObjectPool.repool(self);


func _is_playing()->bool:
	return (_animated_sprite_3d && _animated_sprite_3d.is_playing()) or\
			(_animation_player && _animation_player.is_playing()) or\
			(_cpu_particles_3d && _cpu_particles_3d.is_emitting()) or\
			(_gpu_particles_3d && _gpu_particles_3d.is_emitting());

func _randomizeAnimation():
	if animationSpeedScaleRange != 0:
		var extra:float = (randf() - 0.5) * animationSpeedScaleRange
		if _animated_sprite_3d:
			_animated_sprite_3d.speed_scale = _animated_sprite_3d_original_speed_scale + extra
		if _animation_player:
			_animation_player.speed_scale = _animation_player_original_speed_scale + extra
		if _cpu_particles_3d:
			_cpu_particles_3d.speed_scale = _cpu_particles_3d_original_speed_scale + extra
		if _gpu_particles_3d:
			_gpu_particles_3d.speed_scale = _gpu_particles_3d_original_speed_scale + extra

func _randomizePosition():
	if xzRandomRange != 0:
		var xzRange := Vector3(randf() - 0.5, 0, randf() - 0.5).normalized() * randf() * xzRandomRange;
		self.global_position += xzRange;
	if yRandomRange != 0:
		var yRange := Vector3(0, randf() - 0.5, 0) * yRandomRange;
		self.global_position += yRange;

func _joint_instantiates():
	if jointInstantiates:
		for scene:PackedScene in jointInstantiates:
			InstantiateUtils.InstantiateInTree(scene, self);
