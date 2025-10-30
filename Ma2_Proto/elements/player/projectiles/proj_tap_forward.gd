extends Area3D

@export var projectileVelocityRelative:Vector3 = Vector3.FORWARD * -100;
@export var projectileVelocityAbsolute:Vector3 = Vector3.FORWARD * -100;
@export var camera_multiplier:Vector3 = Vector3(1,0,1);
@export var amountDamage:float = 4;
@export var vfxHit:PackedScene;
@export var vfxHitRadius:float = 0.5;
@export var scores:bool = true;
@export var recover_mana:bool = false;

@export_category("Bonus")
@export var bonus_resource:UpgradeInfo;
@export var damage_per_bonus:float;

var velocity:Vector3;

func _physics_process(delta):
	velocity = self.transform.basis * projectileVelocityRelative + projectileVelocityAbsolute;
	var cam:Vector3 = LevelCameraController.instance.last_physics_step_movement * camera_multiplier;
	position += velocity * delta + cam;

func _on_visible_on_screen_notifier_3d_screen_exited():
	ObjectPool.repool(self);

func get_damage()->float:
	if bonus_resource:
		return amountDamage + bonus_resource.get_progress() * damage_per_bonus;
	else:
		return amountDamage;

func _on_body_entered(body:Node3D):
	var node:Node = body as Node;
	#node = node.get_parent();
	var damData:Health.DamageData = Health.DamageData.new(get_damage(), self, scores, recover_mana)
	Health.Damage(node, damData, true);
	var center:Vector3 = (self.global_position + body.global_position) * 0.5;
	VFX_Utils.instantiate_vfx_set_for_damage(damData, center, vfxHit, vfxHitRadius);
	#TODO make the vfx in the correct position here
