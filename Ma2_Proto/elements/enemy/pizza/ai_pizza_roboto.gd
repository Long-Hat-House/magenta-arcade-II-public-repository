extends AI_WalkAndDo

var body:CharacterBody3D;
var anim:AnimationPlayer;
var nodeToKill:Node;
var score:ScoreGiver;
@onready var screen_notifier: VisibleOnScreenNotifier3D = $Body/VisibleOnScreenNotifier3D

@export var simpleAnimation:AnimationPlayerProxy;
@export var walkAnimation:String;
@export var idleAnimation:String;
@export var pressable:bool;
@export var vfxOnVanish:PackedScene;
@export var timeLeft:float = -1.0;

@export var damage:float = 0.5;

var outside_screen_count:float = 20;

var debug_name:String;

func ai_ready() -> void:
	body = $Body as CharacterBody3D;
	anim = $AI/AnimationPlayer as AnimationPlayer;
	nodeToKill = self as Node;
	score = $Body/ScoreGiver as ScoreGiver;
	stopped = false;
	debug_name = self.get_full_name();

func ai_physics_on_collision(otherCollider:CollisionObject3D):
	if pressable and otherCollider is PlayerToken:
		health.damage_kill(otherCollider, true);
	else:
		super.ai_physics_on_collision(otherCollider);

func ai_before_walk()->void:
	if not simpleAnimation:
		print("[PIZZA] %s using simple animation null" % [debug_name]);
	simpleAnimation.animationPlayer.play(walkAnimation);


func ai_after_walk()->void:
	simpleAnimation.animationPlayer.play(idleAnimation);


func ai_physics_process(delta:float):
	ai_physics_walk_and_do(body, delta);
	#print("%s animation is %s" % [self, simpleAnimation.animationPlayer.current_animation]);
	if timeLeft > 0:
		timeLeft -= delta;
		if timeLeft <= 0:
			vanish();

	if outside_screen_count > 0:
		outside_screen_count -= delta;
		if outside_screen_count <= 0:
			print("[PIZZA] destroyed pizza because never entered the screen in 30 seconds!");
			vanish();


func _on_health_dead(h:Health):
	explode();


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	outside_screen_count = -1.0;

func _on_visible_on_screen_notifier_3d_screen_exited():
	if outside_screen_count <= 0:
		vanish();


func explode():
	var tree = get_tree();
	var frames:int = 4;
	while frames > 0:
		frames -= 1;
		await tree.process_frame;
	if vfxOnVanish:
		InstantiateUtils.InstantiateInTree(vfxOnVanish, body);
	nodeToKill.queue_free();


func vanish():
	nodeToKill.queue_free();


func _on_damage_area_on_damaged():
	health.damage_kill(self, false);
