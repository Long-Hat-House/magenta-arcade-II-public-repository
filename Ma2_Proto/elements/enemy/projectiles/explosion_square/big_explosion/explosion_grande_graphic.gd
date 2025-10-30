class_name Graphic_Explosion_Grande extends LHH3D

@onready var anim:AnimationPlayer = $anim
var options_rotation_y:Array[float] = [90*0, 90*1, 90*2, 90*3]
var options_scale_xz:Array[int] = [-1, 1];

func play():
	self.rotation = Vector3.UP * deg_to_rad(options_rotation_y.pick_random());
	self.scale = Vector3(options_scale_xz.pick_random(), 1, options_scale_xz.pick_random());
	anim.play("big_explosion");
	await anim.animation_finished;
