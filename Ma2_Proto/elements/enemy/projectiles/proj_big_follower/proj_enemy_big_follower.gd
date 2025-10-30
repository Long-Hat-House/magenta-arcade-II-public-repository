extends GameElement

@export var firstBurstDistance:float;
@export var firstBurstDuration:float;
@export var delay:float;
@export var distanceBurst:float;
@export var durationBurst:float;
@export var idealHeight:float = 0.25;
@export var trans:Tween.TransitionType = Tween.TRANS_CIRC;
@export var always_unlock_on_redirect:bool = true;
@export var die_on_touch_anything:bool = true;

enum Direction
{
	GoForward,
	GoPlayer,

}
@export var direction_style:Direction = Direction.GoForward;

static var i:int;

var currentRoutine:int;

var lock_node:Node3D;
var lock_direction:Vector3;
var lock_only_positive:bool;
var lock_old_position:Vector3;

var burst_position:Vector3;
var burst_old_position:Vector3;

var can_die:bool;

func _ready():
	name = "shot_%s" % i;
	i+=1;

func _process(delta:float):
	position += locked_process(delta) + burst_process(delta);

func lock_in_vector(node:Node3D, direction:Vector3, only_positive:bool):
	lock_node = node;
	lock_direction = direction;
	lock_only_positive = only_positive;
	lock_old_position = lock_node.global_position;

func unlock():
	lock_node = null;

func locked_process(delta:float)->Vector3:
	if lock_node and is_instance_valid(lock_node):
		var lock_pos:Vector3 = lock_node.global_position;
		var movement:Vector3 = lock_pos - lock_old_position;

		#var movement_in_direction:Vector3 = movement.project(lock_direction);
		#if lock_only_positive:
			#if movement_in_direction.dot(lock_direction) <= 0.0: movement_in_direction = Vector3.ZERO;
		#
		lock_old_position = lock_node.global_position;

		#print("%s locked in %s -> %s" % [movement, lock_direction, movement_in_direction]);
		return movement;
	else:
		return Vector3.ZERO;


func _enter_tree():
	can_die = false;
	shot_routine(currentRoutine);

func _exit_tree():
	currentRoutine += 1;

func is_valid_routine(routine:int)->bool:
	return routine == currentRoutine and is_valid();

func shot_routine(routine:int):
	await get_tree().process_frame; if not is_valid_routine(routine): return;
	await burst(firstBurstDistance, firstBurstDuration); if not is_valid_routine(routine): return;
	while is_valid_routine(routine):
		#print("[PROJ BIG FOLLOWER] %s -> %s" % [direction_style, Player.get_closest_direction(self.global_position, true).normalized()]);
		match direction_style:
			Direction.GoForward:
				redirect_to(Vector3.BACK);
			Direction.GoPlayer:
				redirect_to(Player.get_closest_direction(self.global_position, true).normalized());
		await timer(delay); if not is_valid_routine(routine): return;
		if always_unlock_on_redirect:
			unlock();
		can_die = true;
		await burst(distanceBurst, durationBurst); if not is_valid_routine(routine): return;

func timer(amount:float):
	if amount > 0:
		await get_tree().create_timer(amount).timeout;

func burst(distance:float, duration:float):
	if duration > 0 and distance > 0:
		var t:Tween = create_tween();
		var yDistance:float = idealHeight - global_position.y
		burst_old_position = burst_position;
		t.tween_property(self, "burst_position", -basis.z.normalized() * distance + Vector3.UP * yDistance, duration).as_relative().set_ease(Tween.EASE_OUT).set_trans(trans);
		await t;

func burst_process(delta:float)->Vector3:
	var mov := burst_position - burst_old_position;
	burst_old_position = burst_position;
	return mov;

func redirect_to(direction:Vector3):
	#print("[PROJ BIG FOLLOWER] Redirect to %s (%s %s)" % [direction, direction_style, name]);
	if direction.length_squared() < 0.01: direction = Vector3.BACK;
	direction.y = 0;
	self.global_basis = Basis.looking_at(direction, Vector3.UP);


func _on_visible_on_screen_notifier_3d_screen_exited():
	vanish();


func _on_vanish_area_area_entered(area: Area3D) -> void:
	if can_die:
		explode();
		vanish();


func _on_vanish_area_body_entered(body: Node3D) -> void:
	if die_on_touch_anything and can_die:
		explode();
		vanish();

func explode():
	pass

func vanish():
	ObjectPool.repool(self);
