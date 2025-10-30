class_name Enemy_LaserRoboto extends AI_WalkAndDo

@onready var body:CharacterBody3D = $Body as CharacterBody3D;
@onready var anim:AnimationPlayer = $AI/AnimationPlayer as AnimationPlayer;
@onready var nodeToKill:Node = self as Node;
@onready var score:ScoreGiver = $Body/ScoreGiver as ScoreGiver;
@onready var laserArea:Enemy_LaserArea = $Body/LaserArea as Enemy_LaserArea;
var tween:Tween;

var amountRot:float;

var bodyInLaser:Node3D;
var enteredScreen:bool;

var deletion_by_screen_protected:float = 0;

@export var angleMax:float;
@export var vfxOnDie:PackedScene;
@export var delayBeforeShooting:float = 0;
@export var inverted_direction:bool = false;
@onready var graphic:Graphic_LaserRoboto = $Body/Render/laserroboto_graphic;

func ai_ready() -> void:
	deletion_by_screen_protected = 1;
	super.ai_ready();

	stopped = false;
	laserArea.stop_laser();
	laserArea.get_parent().remove_child(laserArea);
	self.graphic.get_cannon_point().add_child(laserArea);

	laserArea.position = Vector3.ZERO;
	laserArea.rotation = Vector3.ZERO;

func ai_start():
	deletion_by_screen_protected = 1;
	super.ai_start();

func _process(delta:float):
	var rotatedQuat:Quaternion;
	if inverted_direction:
		rotatedQuat = Quaternion(Vector3.UP, -amountRot);
	else:
		rotatedQuat = Quaternion(Vector3.UP, amountRot);
	var dir:Vector3 = rotatedQuat * Vector3.FORWARD;
	self.graphic.direct_neck(dir);
	deletion_by_screen_protected -= delta;

func ai_before_walk():
	graphic.set_walking(1);
	graphic.set_shooting(Graphic_LaserRoboto.ShootPhase.Idle);

func ai_after_walk():
	graphic.set_walking(0);
	if not enteredScreen:
		await $Body/VisibleOnScreenNotifier3D.screen_entered;
		if not self.is_valid():
			return;
	if delayBeforeShooting > 0:
		await get_tree().create_timer(delayBeforeShooting).timeout;
		if not self.is_valid():
			return;
	while true:
		await Tokenizer.await_next_token_and_pick(Tokenizer.LASER_TOKEN, self);
		#TO LASER POSITION
		tween = create_tween();
		tween.tween_property(self, "amountRot", deg_to_rad(-angleMax * 0.5), $TimerAfter.wait_time * 0.5).set_ease(Tween.EASE_OUT);
		await tween.finished;
		if not self.is_valid():
			return;

		#PRE LASER
		laserArea.pre_laser();
		graphic.set_shooting(Graphic_LaserRoboto.ShootPhase.Pre);
		$TimerWarning.start();
		await $TimerWarning.timeout;
		if not self.is_valid():
			return;

		#DURING LASER
		laserArea.start_laser();
		tween = create_tween();
		tween.tween_property(self, "amountRot", deg_to_rad(angleMax * 0.5), $TimerLaser.wait_time);
		graphic.set_shooting(Graphic_LaserRoboto.ShootPhase.Shoot);
		$TimerLaser.start();
		await $TimerLaser.timeout;
		if not self.is_valid():
			return;

		Tokenizer.free_token(Tokenizer.LASER_TOKEN, self);

		#AFTER LASER
		laserArea.stop_laser();
		$TimerAfter.start();
		await $TimerAfter.timeout;
		if not self.is_valid():
			return;
		graphic.set_shooting(Graphic_LaserRoboto.ShootPhase.Post);
		tween = create_tween();
		tween.tween_property(self, "amountRot", deg_to_rad(0), $TimerAfter.wait_time * 0.5).set_ease(Tween.EASE_IN);
		await tween.finished;
		if not self.is_valid():
			return;

func ai_physics_process(delta:float):
	if ai_physics_walk_and_do(body, delta):
		laser_physics_process(delta);

func laser_physics_process(delta:float):
	#print("yooo %s" % [rotateLaser]);
	#Draw3D.move_capsule_line(laserAfter, pos1, pos2);
	pass;


func _on_health_dead(health):
	var tree := get_tree();
	var frames:int = 4;
	while frames > 0:
		frames -= 1;
		await tree.process_frame;
	if is_instance_valid(self):
		if vfxOnDie:
			InstantiateUtils.InstantiateInTree(vfxOnDie, body);
		queue_free();


func _on_health_hit(damage, health):
	anim.play("damaged");
	Health.DamageFeedback($Body/Render as Node3D, damage);
	await anim.animation_finished;
	anim.play("idle");


func _on_visible_on_screen_notifier_3d_screen_entered():
	enteredScreen = true;

func _on_visible_on_screen_notifier_3d_screen_exited():
	enteredScreen = false;

	if deletion_by_screen_protected <= 0:
		queue_free()
