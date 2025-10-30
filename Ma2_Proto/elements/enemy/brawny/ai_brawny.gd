class_name AI_Brawny extends AI_Base

const MESH_FLOOR_DESTROYED = preload("res://elements/enemy/brawny/Mesh/mesh_floor_destroyed.tscn")

signal fall_finished()

@export var heightFall = 30;
@export var cannon:PackedScene;
@export var cannonPositions:Array[int] = [0,1,2,3,4,5];
@export var explosionVFX:PackedScene;
@export var fall_shake:CameraShakeData;
@onready var brawny_graphic:Graphic_Brawny = $Body/Render/brawny_graphic
@onready var collision = $Body/CollisionShape3D
@onready var collisionDamage = $Body/DamageArea/CollisionShape3D2
@onready var damageArea = $Body/DamageArea
@onready var explosion_area:VisibleOnScreenNotifier3D = $Body/ExplosionArea;
@onready var screen_notifier:VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D;

@export_category("Brawny Audio")
@export var sfx_fall_pre:WwiseEvent
@export var sfx_fall_impact:WwiseEvent

var initial_position:Vector3;

var body:CharacterBody3D;

var laser:Enemy_LaserArea;
var tween:Tween;
var dead:bool;

var amountArmsRotated:float = 1;

# Called when the node enters the scene tree for the first time.
func _ready():
	health = %Health;
	body = $Body
	laser = $Body/LaserArea as Enemy_LaserArea;
	laser.stop_laser();
	body.hide()
	initial_position = body.position;
	for pos:int in cannonPositions:
		var inst:Node3D = cannon.instantiate() as Node3D;
		brawny_graphic.attach_to_cannon_slot(inst, pos);

	behaviour();

func behaviour():
	collision.disabled = false;
	collisionDamage.disabled = false;
	body.position = initial_position + Vector3.UP * heightFall;

	if not screen_notifier.is_on_screen():
		await screen_notifier.screen_entered;
		if not is_valid(): return;

	body.show()
	tween = create_tween();
	tween.tween_property(body, "position:y", 0, $"Fall Time".wait_time).set_ease(Tween.EASE_IN);
	brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.CloseFace);
	$"Fall Time".start();
	if sfx_fall_pre: sfx_fall_pre.post(self)
	await $"Fall Time".timeout;
	if not is_valid(): return;
	if sfx_fall_impact: sfx_fall_impact.post(self)
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash)
	if fall_shake:
		fall_shake.screen_shake();
	fall_finished.emit()
	var floor_destroyed = MESH_FLOOR_DESTROYED.instantiate()
	floor_destroyed.position = position
	Game.instance.add_child(floor_destroyed)

	brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.PostFall)
	await brawny_graphic.get_animator().animation_finished;
	if not is_valid(): return;

	while not _should_stop_behaviour():
		#print("%s starting loop" % [self]);
		$Return.start();
		laser.stop_laser();
		tween = create_tween();
		tween.tween_property(self, "amountArmsRotated", 1, $Return.wait_time);
		brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.Idle);
		await $Return.timeout;
		if _should_stop_behaviour(): break;

		$Idle.start();
		await $Idle.timeout;
		if _should_stop_behaviour(): break;

		await Tokenizer.await_next_token_and_pick(Tokenizer.LASER_TOKEN, self);

		$"Warning Laser".start();
		laser.pre_laser();
		tween = create_tween();
		tween.tween_property(self, "amountArmsRotated", 0, $"Warning Laser".wait_time).set_ease(Tween.EASE_IN);
		#laser.global_transform.basis = laser.global_transform.basis.looking_at(-Player.get_closest_direction(laser.global_position), Vector3.UP);
		brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.Pre);
		await $"Warning Laser".timeout;
		if _should_stop_behaviour(): break;

		tween = null;
		$Laser.start();
		laser.start_laser();
		brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.Shoot);
		await $Laser.timeout;

		Tokenizer.free_token(Tokenizer.LASER_TOKEN, self);

func _should_stop_behaviour():
	return dead or not is_valid();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.brawny_graphic.set_arms_opened(amountArmsRotated);


func _on_health_dead(health):
	dead = true;
	collision.disabled = true;
	collisionDamage.disabled = true;
	laser.stop_laser();
	if tween:
		tween.stop();

	self.brawny_graphic.set_animation(Graphic_Brawny.AnimPhase.Dead);
	var deathTween:Tween = self.create_tween();
	VFX_Utils.make_vfxs_in_region(deathTween, [explosionVFX], null, explosion_area, 15, 0.75).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
	await deathTween.finished;
	if not is_instance_valid(self):
		return;
	VFX_Utils.make_vfxs_in_region(null, [explosionVFX], null, explosion_area, 10, 0);

	self.queue_free.call_deferred();


func _on_health_hit(damage, health):
	Health.DamageFeedback(brawny_graphic.get_head(), damage);

func _on_visible_on_screen_notifier_3d_screen_entered():
	pass;

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free.call_deferred();
