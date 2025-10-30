extends Node3D

@export var mesh:Node3D

@export var scale_in:float = 0.1;
@export var interval:float = 0.25;
@export var scale_out:float = 0.25;

const down_scale:Vector3 = Vector3.ONE * 0.001;

func _enter_tree() -> void:
	if not self.is_node_ready():
		await ready;
	var t := create_tween();
	mesh.scale = down_scale;
	t.tween_property(mesh, "scale", Vector3.ONE, scale_in).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
	t.tween_interval(interval);
	t.tween_property(mesh, "scale", down_scale, scale_out).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC);
	await t.finished;
	ObjectPool.repool(self);
