extends Node3D

@export var explosion:PackedScene;
var exploding = false;

func explode():
	if exploding: return;
	exploding = true;
	await create_tween()\
			.tween_property($Squished, "scale", Vector3.ONE * 1.2 + Vector3.UP * 0.2, 0.075)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)\
			.finished
	if is_instance_valid(self):
		InstantiateUtils.InstantiateInTree(explosion, self);
		queue_free();
