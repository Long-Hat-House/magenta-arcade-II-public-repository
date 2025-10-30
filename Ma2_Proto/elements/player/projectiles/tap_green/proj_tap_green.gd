extends Node3D

@export var proj_to_instantiate:Array[PackedScene];
@export var projectile_origin:Node3D;
@export var interval_between_projectiles:float = 0.25;
@export var projectiles:PackedByteArray;
@export var _projectiles:Array[int]

@onready var scaler: Node3D = $Scale

func shoot(projectile1:PackedScene, projectile2:PackedScene) -> void:
	make_inverted(InstantiateUtils.InstantiateInTree(projectile1, projectile_origin, Vector3.ZERO, true), true);
	make_inverted(InstantiateUtils.InstantiateInTree(projectile2, projectile_origin, Vector3.ZERO, true), false);

func make_inverted(p:Node, inverted:bool):
	var child := p.find_child("*Wave*", false);
	if child:
		child.set_inverted(inverted);

func grow(to:Vector3, ease:Tween.EaseType, trans:Tween.TransitionType)->Tween:
	var growT:Tween = create_tween();
	growT.tween_property(scaler, "scale", Vector3.ONE, 0.40).set_ease(ease).set_trans(trans);
	return growT;

func next_projectile()->PackedScene:
	var index:int;
	if projectiles.size() > 0:
		index = _projectiles.pop_back();
	else:
		index = 0;
	return proj_to_instantiate[index];

func _enter_tree() -> void:
	if !self.is_node_ready(): await ready;
	for i in range(projectiles.size() -1, -1, -1):
		_projectiles.append(projectiles[i]);

	scaler.scale = Vector3.ONE * 0.01;
	var amount_projectiles:int = projectiles.size();
	grow(Vector3.ONE * 1.25, Tween.EASE_OUT, Tween.TRANS_ELASTIC).finished.connect(func():
		var t := create_tween();
		t.tween_callback(func():
			shoot(next_projectile(), next_projectile());
			);
		t.tween_interval(interval_between_projectiles);
		t.set_loops(amount_projectiles / 2); ##shoots twice
		t.finished.connect(func():
			grow(Vector3.ONE * 0.01, Tween.EASE_IN, Tween.TRANS_CIRC).finished.connect(func():
				queue_free();
				, CONNECT_ONE_SHOT)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)

func _process(delta: float) -> void:
	position += LevelCameraController.instance.last_frame_movement.project(Vector3.FORWARD);
