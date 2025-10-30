extends Node3D

var currentScale:Vector3;

@export var explosionVFX:PackedScene;
@export var vfxRandomRadius:float = 0.05;

var a:Array[Node3DTarget];

func _ready():
	currentScale = self.scale;
	a = [];

func _on_health_dead(health):
	var count := Node3DTarget.FindTargets(self, a);
	for target:Node3DTarget in a:
		var randOffset:Vector3 = Vector3(randf() - 0.5, 0, randf() - 0.5);
		randOffset = randOffset.normalized() * vfxRandomRadius;
		print("INSTANTIATING targets in brawny arm in %s %s" % [target, target.global_position]);
		InstantiateUtils.InstantiateInTree(explosionVFX, target, randOffset, true);
	self.queue_free();
