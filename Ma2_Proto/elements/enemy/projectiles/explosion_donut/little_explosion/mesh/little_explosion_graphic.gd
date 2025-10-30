class_name Graphic_Little_Explosion extends LHH3D

@onready var animation:AnimationPlayer = $anim

func play()->void:
	self.rotation = Vector3.UP * randf_range(0, 360);
	animation.play("little_explosion");
	await animation.animation_finished;
