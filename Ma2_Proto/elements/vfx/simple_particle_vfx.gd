extends Node3D

@export var cpuParticle:CPUParticles3D;
@export var gpuParticle:GPUParticles3D;

var readied:bool;
var followed:Node3D;
var ever_followed:bool;
@export var will_self_destruct_on_not_following:bool  = true;

func follow(node3D:Node3D):
	followed = node3D;
	ever_followed = true;

func _enter_tree() -> void:
	if readied:
		_play();


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	readied = true;
	_play();


func _play() ->void:
	self.basis = self.basis.orthonormalized();
	if cpuParticle and cpuParticle.visible:
		cpuParticle.emitting = true;
		cpuParticle.restart();
		if cpuParticle.one_shot:
			await cpuParticle.finished;
		else:
			if will_self_destruct_on_not_following:
				await await_followee_to_disappear();
				cpuParticle.emitting = false;
				await get_tree().create_timer(1).timeout;
			else:
				return;
	elif gpuParticle and gpuParticle.visible:
		gpuParticle.emitting = true;
		gpuParticle.restart();
		if gpuParticle.one_shot:
			await gpuParticle.finished;
		else:
			if will_self_destruct_on_not_following:
				await await_followee_to_disappear();
				gpuParticle.emitting = false;
				await get_tree().create_timer(1).timeout;
			else:
				return;
	ObjectPool.repool(self);

func await_followee_to_disappear():
	while followed and followed.get_parent():
		await get_tree().process_frame;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if followed:
		self.global_position = followed.global_position;
