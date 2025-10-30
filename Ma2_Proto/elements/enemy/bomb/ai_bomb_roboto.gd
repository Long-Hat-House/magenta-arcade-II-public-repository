extends AI_WalkAndDo

@export var vfx_jump_poolable:PackedScene
@export var sfx_jump:AkEvent3D

@onready var graphic:Graphic_Bomb = $graphic
@export var time_to_explode:float = 0.1;
@export var attack_scene:PackedScene;
@export var explosion_vfx:PackedScene;
@onready var body:CharacterBody3D = $"."
@onready var anim:AnimationPlayer = $AnimationPlayer
@onready var warning:Attack_Preview = $BaseAttackPreview
@export var needs_to_be_in_screen:bool = false;
@onready var accessibility_high_contrast_object: AccessibilityHighContrastObject = $AccessibilityHighContrastObject

var beginning_position:Vector3;
var beginning_maxDistance:float;
var in_screen:bool;


func ai_physics_process(delta:float):
	if needs_to_be_in_screen:
		if not in_screen:
			await ($VisibleOnScreenNotifier3D as VisibleOnScreenNotifier3D).screen_entered;
	ai_physics_walk_and_do(body, delta);


func ai_before_walk():
	beginning_position = self.global_position;
	beginning_maxDistance = self.distanceMax;
	anim.play("warning");


func _process(delta):
	#warning.set_preview_closeness(1.0 - (self.distanceMax / beginning_maxDistance));
	warning.global_position = beginning_position + self.walkVelocity.normalized() * beginning_maxDistance;


func _timer(seconds:float):
	await get_tree().create_timer(seconds).timeout;


func ai_when_jump():
	graphic.jump();
	sfx_jump.post_event()
	if vfx_jump_poolable:
		var fx = ObjectPool.instantiate(vfx_jump_poolable).node
		fx.global_position = graphic.global_position
		Game.instance.add_child(fx)

func ai_after_jump():
	await graphic.land();
	if not is_valid(): return;
	await graphic.pre_jump();
	if not is_valid(): return;
	set_ready_to_do_another_tween();

func ai_after_walk():
	graphic.idle();
	await _timer(time_to_explode * 0.15);
	accessibility_high_contrast_object.change_group(&"danger");
	warning.warn(time_to_explode * 0.70);
	await _timer(time_to_explode * 0.85);
	if not self.is_valid():
		return;
	if attack_scene:
		InstantiateUtils.InstantiateInSamePlace3D(attack_scene, body);
	queue_free();


func _on_health_hit(damage, health):
	Health.DamageFeedback(graphic, damage);


func _on_health_dead(health):
	var tree := get_tree();
	var frames:int = 4;
	while frames > 0:
		frames -= 1;
		await tree.process_frame;
	if is_instance_valid(self):
		InstantiateUtils.InstantiateInSamePlace3D(explosion_vfx, body);
		queue_free();

func _on_visible_on_screen_notifier_3d_screen_entered():
	in_screen = true;

func _on_visible_on_screen_notifier_3d_screen_exited():
	in_screen = false;
	queue_free();
