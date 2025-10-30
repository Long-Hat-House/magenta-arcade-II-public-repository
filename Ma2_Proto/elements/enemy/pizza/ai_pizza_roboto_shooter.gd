extends AI_WalkAndDo

var body:CharacterBody3D;
var anim:AnimationPlayer;
var spawnPlace:Marker3D;
var nodeToKill:Node;
var score:ScoreGiver;
@export var instantiateInPlace:PackedScene;
@export var simpleAnimation:AnimationPlayerProxy;
@export var walkAnimation:String;
@export var idleAnimation:String;
@export var vfxVanish:PackedScene;
@export var cannon:AI_Cannon; # so level can manipulate this on level design

func ai_ready() -> void:
	body = $Body as CharacterBody3D;
	anim = $AI/AnimationPlayer as AnimationPlayer;
	spawnPlace = $Body/SpawnPlace as Marker3D;
	nodeToKill = self;
	score = $Body/ScoreGiver as ScoreGiver;


func ai_before_walk()->void:
	simpleAnimation.animationPlayer.play(walkAnimation);

func ai_after_walk()->void:
	simpleAnimation.animationPlayer.play(idleAnimation);

func ai_physics_process(delta:float):
	ai_physics_walk_and_do(body, delta);

func vanish():
	nodeToKill.queue_free();

func _on_health_dead(h:Health):
	if not score:
		return;
	if vfxVanish:
		InstantiateUtils.InstantiateInTree(vfxVanish, body);
	var newPizza:Node3D = instantiateInPlace.instantiate() as Node3D;
	for group in get_groups():
		#print("[PIZZA] adding %s to group %s" % [newPizza, group]);
		newPizza.add_to_group(group)
	self.get_parent().add_child(newPizza);
	newPizza.global_transform = spawnPlace.global_transform;
	var newPizzaWalk:AI_WalkAndDo = newPizza as AI_WalkAndDo;
	if newPizzaWalk:
		if spawn_direction != Vector3.ZERO:
			var quatToAdd:Quaternion = Quaternion(newPizzaWalk.walkVelocity, newPizzaWalk.walkVelocityAdd);
			newPizzaWalk.walkVelocity = spawn_direction.normalized() * newPizzaWalk.walkVelocity.length();
			newPizzaWalk.walkVelocityAdd = quatToAdd * spawn_direction.normalized() * newPizzaWalk.walkVelocityAdd.length();
	var newPizzaHealth:Health = Health.FindHealth(newPizza);
	if newPizzaHealth:
		newPizzaHealth.set_immunity_mark(0.05);
	vanish();


func _on_health_hit(amount:Health.DamageData, h:Health):
	if not anim:
		return;
	anim.play("damaged");
	await anim.animation_finished;
	anim.play("idle");

func _on_visible_on_screen_notifier_3d_screen_exited():
	vanish();
