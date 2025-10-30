class_name AI_WalkAndDo
extends AI_Base

@export var distanceMax:float;
@export var damage_on_collision:float = 1.0;
@export var kill_self_on_collision:bool;
@export var await_to_kill_self_on_collision:float = 0.1;
@export var walkAndStop:bool;
@export var absoluteVelocity:bool;
@export var invertedPosition:bool;
@export var spawn_direction:Vector3 = Vector3.BACK;
@export var debug:bool;
@export var debug_every_frame:bool;

var vertical_tween:Tween;
@export var vertical_tween_ease:Tween.EaseType = Tween.EASE_OUT;
@export var vertical_tween_trans:Tween.TransitionType = Tween.TRANS_QUAD;
@export var needs_screen_to_start:VisibleOnScreenNotifier3D;
@export var time_after_screen_to_start_min:float;
@export var time_after_screen_to_start_max:float;
var time_after_screen_to_start:float;
var last_entered_screen_mark:int;


@export_group("Constant walking")
@export var walkVelocity:Vector3;
@export var walkVelocityAdd:Vector3;
@export var accelerationBegin:float = 4.25;
@export var accelerationEnd:float = 0;
@export var accelerationDuration:float = 2.5;
@export var accelerationEase:Tween.EaseType = Tween.EASE_OUT;
@export var accelerationTrans:Tween.TransitionType = Tween.TRANS_QUAD;
var _accTween:Tween;
var _accValue:float = 0;

@export_group("Tween walking")
@export var useTweenJumpInstead:bool;
@export var tweenJumpDistance:Vector3 = Vector3.BACK * 5;
@export var tweenJumpHeight:float = 0;
@export var tweenJumpDuration:float = 1;
@export var tween_jump_duration_add_per_jump:float = 0;
@export var tweenJumpAwaitConfirm:bool = false;
@export var tweenJumpEase:Tween.EaseType = Tween.EASE_OUT;
@export var tweenJumpTrans:Tween.TransitionType = Tween.TRANS_QUAD;
@export var tweenWaitTimeBetween:float = 1;
var tween_jump_duration_now:float;
var _walkAndDoTween:Tween;
var _jumpYTween:Tween;
var _tweenTargetPosition:Vector3;
var _tweenHeight:float;
var _canDoJumpTween:bool = true;

var paralized:bool;
var stopped:bool;

#PUBLIC FUNCTIONS
func stop() -> void:
	if debug: print("[AI_WALK_AND_DO] %s stopped!" % [self]);
	stopped = true;

	time_after_screen_to_start = randf_range(time_after_screen_to_start_min, time_after_screen_to_start_max);

	if needs_screen_to_start:
		if not needs_screen_to_start.is_on_screen():
			await needs_screen_to_start.screen_entered;
			await get_tree().create_timer(time_after_screen_to_start).timeout;
		else:
			var time_left:float = time_after_screen_to_start - time_since_entered_screen();
			if time_left > 0:
				await get_tree().create_timer(time_left).timeout;


	ai_after_walk();
	alreadyWalked = false;

#PROTECTED, ABSTRACT FUNCTIONS

#func ai_physics_process(delta:float):
#	pass;

func ai_physics_on_collision(otherCollider:CollisionObject3D):
	if debug:
		print("[AI_WALK_AND_DO] %s collided with %s" % [self, otherCollider]);
	var otherParent = otherCollider.get_parent();
	Health.Damage(otherParent, Health.DamageData.new(damage_on_collision, self));
	if kill_self_on_collision and not paralized:
		paralized = true;
		if await_to_kill_self_on_collision > 0:
			await get_tree().create_timer(await_to_kill_self_on_collision, false).timeout;
		if is_instance_valid(health) and is_instance_valid(otherCollider):
			health.damage_kill(otherCollider, false);

func time_since_entered_screen()->float:
	return float(Time.get_ticks_msec() - last_entered_screen_mark) / 1000.0;

func ai_start():
	super.ai_start();
	tween_jump_duration_now = tweenJumpDuration;

	if needs_screen_to_start:
		needs_screen_to_start.screen_entered.connect(func():
			last_entered_screen_mark = Time.get_ticks_msec();
			)
	if invertedPosition and walkAndStop:
		var p:Node3D = self as Node3D;
		if p:
			var direction:Vector3 = (walkVelocity + walkVelocityAdd).normalized();
			if not absoluteVelocity:
				direction = p.global_basis.orthonormalized() * direction;
			var debug_origin:Vector3 = p.global_position;
			p.global_transform = p.global_transform.translated(-direction * distanceMax);
		else:
			printerr("[AI_WALK_AND_DO] Inverted position but %s was not a Node3D!" % [self]);

func ai_after_walk():
	pass;

func ai_before_walk():
	pass;

func ai_when_jump():
	pass;

func ai_after_jump():
	pass;

## to make this work, do this:
#func ai_physics_process(delta:float):
	#ai_physics_walk_and_do(body, delta);

var alreadyWalked:bool = false;

func tween_displacement(to:Vector3, body:CharacterBody3D, duration:float, duration01:float = 1)->Tween:
	var newTween := create_tween();
	_tweenTargetPosition = body.position;
	newTween.tween_property(self, "_tweenTargetPosition", body.position + to, duration * duration01).set_ease(tweenJumpEase).set_trans(tweenJumpTrans);
	return newTween;

func tween_vertical(duration01:float = 1)->Tween:
	var newTween := create_tween();
	newTween.tween_property(self, "_tweenHeight", 1, tweenJumpDuration * duration01 * 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	newTween.tween_property(self, "_tweenHeight", 0, tweenJumpDuration * duration01 * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	return newTween;

func set_ready_to_do_another_tween():
	_canDoJumpTween = true;

func keep_tweening(body:CharacterBody3D):
	if not is_valid(): return;
	var tjDistance := tweenJumpDistance.length();
	var tjNormalized := tweenJumpDistance.normalized();
	var basisNormalized := body.global_basis.orthonormalized();
	while self.is_valid():
		if distanceMax <= 0:
			stop();
			return;
		else:
			if tjDistance > 0:
				var distanceJumpLength = min(distanceMax, tjDistance);
				var distanceJump:Vector3 = tjNormalized * distanceJumpLength;
				if not absoluteVelocity:
					distanceJump = basisNormalized * distanceJump;
				var duration01:float = distanceJumpLength / tjDistance;
				_walkAndDoTween = tween_displacement(distanceJump, body, tween_jump_duration_now, duration01);
				_walkAndDoTween.tween_callback(func(): self.tween_jump_duration_now += self.tween_jump_duration_add_per_jump);
				if tweenJumpHeight != 0: _jumpYTween = tween_vertical(duration01);
				distanceMax -= distanceJumpLength;
				_canDoJumpTween = false;
				if debug: print("[AI_WALK_AND_DO] %s jumping..." % [self]);
				ai_when_jump();
				await _walkAndDoTween.finished;
				if not is_valid(): return;
				ai_after_jump();
				if debug: print("[AI_WALK_AND_DO] %s Jumped!" % [self]);
			if tweenWaitTimeBetween > 0:
				if debug: print("[AI_WALK_AND_DO] %s awaiting timer for %s seconds..." % [self, tweenWaitTimeBetween]);
				await get_tree().create_timer(tweenWaitTimeBetween).timeout;
				if not is_valid(): return;
			if tweenJumpAwaitConfirm:
				if debug: print("[AI_WALK_AND_DO] %s awaiting confirmation for next jump..." % [self]);
				while not _canDoJumpTween:
					if not is_valid() || !get_tree(): return;
					await get_tree().process_frame;
					if not is_valid(): return;



func _setup_acceleration_tween():
	if accelerationBegin != accelerationEnd:
		if accelerationDuration > 0:
			_accTween = create_tween();
			_accTween.tween_method(func(value:float):
				self._accValue = value
			, accelerationBegin, accelerationEnd, accelerationDuration)\
			.set_ease(accelerationEase).set_trans(accelerationTrans);
		else:
			_accValue = accelerationEnd;

## Walk and do, as a lot of enemies in MA2 do. Return if it already stopped or if it will walk forever.
func ai_physics_walk_and_do(body:CharacterBody3D, delta:float) -> bool:
	if not body or not is_instance_valid(body) or (not body.is_inside_tree()):
		push_error("[AI_WALK_AND_DO] no body is '%s'!" % self)
		printerr("[AI_WALK_AND_DO] no body in '%s'!" % [self]);
		return false;
	#if paralized:
		#return false;
	if not stopped:
		if not alreadyWalked:
			alreadyWalked = true;
			if debug: print("[AI_WALK_AND_DO] %s beginning to walk!" % [self]);
			ai_before_walk();
			if useTweenJumpInstead:
				keep_tweening(body);
			else:
				_setup_acceleration_tween();

		if useTweenJumpInstead:
			_tweenTargetPosition.y = _tweenHeight * tweenJumpHeight;
			body.velocity = _tweenTargetPosition - body.position;
		else:
			walkVelocity += walkVelocityAdd * delta;
			body.velocity = walkVelocity * delta + _accValue * walkVelocity.normalized() * delta;
			if debug_every_frame: print("[AI_WALK_AND_DO] %s walked %s + %s. %s left to go!" % [self, walkVelocity * delta, _accValue * delta, distanceMax]);
			if walkAndStop and distanceMax >= 0:
				distanceMax -= body.velocity.length();
				if distanceMax <= 0:
					stop()
			if not absoluteVelocity:
				body.velocity = body.global_basis.orthonormalized() * body.velocity;
	else:
		body.velocity = Vector3.ZERO;


	
	var collision := body.move_and_collide(body.velocity, true, 0.001, true);
	if collision:
		ai_physics_on_collision(collision.get_collider());
	body.global_position += body.velocity;

#	body.move_and_slide(); #using collision will not always collide with the player correctly every frame
#	for colIndex in range(body.get_slide_collision_count()):
#		var collision = body.get_slide_collision(colIndex);
#		if collision:
#			ai_physics_on_collision(collision.get_collider());
	return stopped or not walkAndStop;
