class_name Health extends LHH

const DAMAGED_MATERIAL:StandardMaterial3D = preload("res://systems/health/damaged_material.tres")
const DAMAGED_SOUND_BASIC = preload("res://systems/health/damaged_sound_basic.tscn")
const INVULNERABLE_SOUND_BASIC = preload("res://systems/health/invulnerable_sound_basic.tscn")

@export_group("Game Design")
@export var max_amount:float = 1.0;
func get_max_amount()->float:
	return max_amount;
@export var min_amount:float = 0.0;
func get_min_amount()->float:
	return min_amount;
@export var immortal:bool = false;
@export var immunity_after_ready:float = 0.25;
@export var invulnerable:bool = false;
@export var invulnerable_if_off_screen:VisibleOnScreenNotifier3D;
@export var intangible:bool = false;
@export var intangible_if_dead:bool = true;
@export var damage_reduction:float = 0;
@export var max_life_on_enter_tree:bool = true;
@export var max_life_on_ready:bool = false;
@export var wait_until_send_death_signal:float = 0;
## Use this to only damage if after n frames, both the Health and the origin are valid. Good to use if both the Healths damage each other by colliding, and one has priority for example.
@export var frames_of_damage_delay:int;
@export var frames_until_send_death_signal:int = 0;
@export var to_queue_free_on_death:Array[Node];

@export_group("Visual feedback")
@export var feedback:Array[Node3D];
@export var feedback_scale_multiplier:Vector3 = Vector3(0.2,-0.1,0.2);
@export var frame_freeze_on_death:FloatValue;
@export var screen_shake_on_damaged:CameraShakeData;
@export var screen_shake_on_death:CameraShakeData;
enum Style{
	SCALE_AND_COLOR,
	SCALE,
	COLOR,
	NONE
}
@export var visual_style:Style = Style.SCALE_AND_COLOR;
@export var feedback_deepness:int = 4;
@export var feedback_ignore_contains_divided_by_commas:String = "";

class Feedbacker:
	var mesh:MeshInstance3D;
	var old_material:Material;
	var set_old_material:bool;
	var deepness:int = 0;
	var original_scale:Vector3;
	var set_original_scale:bool;
	var aabb_size:Vector3;
	var has_parent:bool;

@export_group("Sound feedback")
@export var use_default_sound:bool = true;
@export var hit_sfx:AkEvent3D;
@export var invulnerable_sfx:AkEvent3D;

@export_group("Debugging")
@export var debug:bool;
@export var debug_call_stack_of_change_amount:bool;

var _feedback_meshes:Array[Feedbacker];
var currentAmount:float:
	get: return currentAmount;
	set(value):
		if debug:
			print("SETTING '%s' HEALTH AMOUNT AS %s (was %s)" % [self, value, currentAmount]);
		if debug_call_stack_of_change_amount:
			print_stack();
		currentAmount = value;
var _initialized:bool = false;

var alreadyDamaged:Array[Node] = [];
var currentImmunityPriority:int;
var immunityMark:int;
## When the health has changed its amount
signal healthChange(health:Health);
## When the health has been hit with the damage() function and the damage is different than zero.
signal hit(damage:DamageData, health:Health);
## When the health has been hit with the damage() function.
signal try_damage(health:Health);
signal try_damage_parameterless;
## When the health's amount just became 0 or less.
signal dead(health:Health);
## When the health's amount just became 0 or less, with the damage. The damage can be null if invoked from set_health().
signal dead_damage(damage:DamageData, health:Health);
signal hit_parameterless;
signal dead_parameterless;
signal revived_parameterless;
signal alive_change(is_alive:bool);

## Data for damaging. Made a class because easier to make a change and every function already works
class DamageData:
	var amount:float;
	var origin:Node3D;
	var scores:bool = true;
	var recover_tap_ammo:bool = false;
	var overlap_invulnerablity:bool = false;
	var immunityTime:float = 0.05;
	var immunityPriority:int = 0;
	var never_delayed:bool = false;
	var frame_freeze_duration:float = 0;
	var debug:bool = false;

	func _init(amount:float = 0.0, origin:Node3D = null, scores:bool = false, recover_tap_ammo:bool = false):
		self.amount = amount;
		self.origin = origin;
		self.scores = scores;
		self.recover_tap_ammo = recover_tap_ammo;

	func set_immunity(immunity_time:float = 0, immunity_priority:int = 0):
		self.immunityTime = immunity_time;
		self.immunityPriority = immunity_priority;

	func set_frame_freeze(frame_freeze:float)->DamageData:
		self.frame_freeze_duration = frame_freeze;
		return self;

	func _to_string() -> String:
		var owner_name:String;
		if origin != null:
			if origin.owner != null:
				owner_name = origin.owner.name;
			else:
				owner_name = origin.name;
		else:
			owner_name = "<none>";

		return "Damage: <%s from %s>" % [
			amount,
			owner_name
			]

var _ready_mark:int;

func _ready():
	if max_life_on_ready:
		currentAmount = get_max_amount();
		wasAlive = true;
	prepare_visual_feedback();
	prepare_sound_feedback();
	
	_ready_mark = Time.get_ticks_msec();
	
func time_since_ready()->float:
	return float(Time.get_ticks_msec() - _ready_mark) * 0.001;

func prepare_visual_feedback():
	_feedback_meshes = [];
	var ignores:Array[String];
	if feedback_ignore_contains_divided_by_commas.is_empty():
		ignores = [];
	elif feedback_ignore_contains_divided_by_commas.contains(","):
		ignores.assign(feedback_ignore_contains_divided_by_commas.split(",", true));
	else:
		ignores = [feedback_ignore_contains_divided_by_commas];
	for f in feedback:
		_find_feedbacks_recursive(f, feedback_deepness, false, ignores);

func prepare_sound_feedback():
	if use_default_sound:
		var possibleParents:Array[Node] = [];
		if not _feedback_meshes.is_empty():
			possibleParents.push_back(_feedback_meshes[0].mesh);
		if not to_queue_free_on_death.is_empty():
			possibleParents.push_back(to_queue_free_on_death[0]);
		possibleParents.push_back(self);

		if hit_sfx == null:
			var sound:AkEvent3D = DAMAGED_SOUND_BASIC.instantiate();
			_add_child_on_first(sound, possibleParents);
			hit_sfx = sound;

		if invulnerable_sfx == null:
			var sound:AkEvent3D = INVULNERABLE_SOUND_BASIC.instantiate();
			_add_child_on_first(sound, possibleParents);
			invulnerable_sfx = sound;

func _add_child_on_first(child:Node, nodes:Array[Node])->bool:
	for node in nodes:
		if node:
			node.add_child(child);
			return true;
	return false;

func _enter_tree():
	if max_life_on_enter_tree:
		currentAmount = get_max_amount();
		wasAlive = true;

	_initialized = true;

## Find a health in an arbitrary node.
static func FindHealth(node:Node, recursive:bool = true, inactive_also:bool = false, includeInternal:bool = false, debug:bool = false) -> Health:
	for child in node.get_children(includeInternal):
		if debug:
			print("[HEALTH DEBUG] looking for health in %s's %s (%s), recursive: %s, enabled: %s %s" % [node, child, child is Health, recursive, 
					node.can_process(), node.process_mode])
		if child is Health:
			if debug:
				print("[HEALTH DEBUG] FOUND HEALTH in %s (but is it enabled? %s %s %s)" % [child, child.can_process(), child.process_mode, child.is_inside_tree()]);
			if not inactive_also: 
				if (child.is_inside_tree() and not child.can_process()): ## For some reason, the player token inside the player is not inside the tree!?
					return;
			return child as Health;
		if recursive:
			var recursiveHealth:Health = FindHealth(child, recursive, inactive_also, includeInternal, debug);
			if recursiveHealth:
				return recursiveHealth;
	if debug:
		print("[HEALTH DEBUG] found no health in %s" % [node]);
	return null;

static func FindAllUniqueHealths(node:Node, arr:Array[Health] = [])->Array[Health]:
	if node is Health:
		if !arr.has(node):
			arr.push_back(node);
			return arr;
	for child in node.get_children():
		FindAllUniqueHealths(child, arr);
	return arr;

static func FindAllUniqueHealths_Nodes(nodes:Array[Node], arr:Array[Health] = [])->Array[Health]:
	for node in nodes:
		for health in FindAllUniqueHealths(node, arr):
			if !arr.has(health):
				arr.append(health);
	return arr;

## Damage a Health found in an arbitrary node with FindHealth(). Returns if it damaged succesfully or not
static func Damage(target:Node, damage:DamageData, recursive:bool = true, includeInternal:bool = false, debug:bool = false) -> bool:
	var health = FindHealth(target, recursive, includeInternal, debug);
	if not health:
		return false;
	else:
		return health.damage(damage);

### Deprecated call - use the feedbacks of the health node instead
static func DamageFeedback(target:Node3D, damage:DamageData, currentScale:Vector3 = Vector3(0,0,0))->Tween:
	return;
	#var tween:Tween = target.create_tween();
	#if currentScale == Vector3.ZERO:
		#currentScale = target.scale;
	#
	#tween.tween_property(target, "scale", currentScale + Vector3.ONE * 0.1, 0.025).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC);
	#tween.tween_property(target, "scale", currentScale, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	#tween.play();
	#
	#return tween;

func set_max_health(amount:float, health_to_max:bool = true, call_events:bool = false):
	max_amount = amount;
	if health_to_max:
		wasAlive = true;
		_initialized = true;
		if call_events:
			set_health(amount);
		else:
			currentAmount = amount;


func set_health(amount:float):
	amount = clampf(amount, get_min_amount(), get_max_amount());
	var changed:bool = amount != currentAmount;
	currentAmount = amount;
	_initialized = true;
	if changed:
		healthChange.emit(self);
		_check_death(null);

func release_min_health():
	min_amount = 0;

func get_health()->float:
	return currentAmount;

func get_health_percentage()->float:
	return get_health() / get_max_amount();

func debug_try_damage(damage:DamageData) -> String:
	var delaying:bool = frames_of_damage_delay > 0 and not damage.never_delayed and damage.origin != null;
	var tangible:bool = !is_intangible();
	var time:bool = Time.get_ticks_msec() > immunityMark;
	var priority:bool = damage.immunityPriority > currentImmunityPriority;
	return ("%s on %s -> %s delaying_damage? %s, tangible %s, %s, time %s (time mark %s, priority %s)" % [
		damage,
		self,
		"HIT!" if tangible and (time or priority) else "MISS",
		delaying,
		tangible,
		"alive" if is_alive() else "dead",
		time or priority,
		time,
		priority,
	]);

func damage(damage:DamageData) -> bool:
	if not _initialized:
		_ready();
	try_damage.emit(self);
	try_damage_parameterless.emit();
	var timeMark:int = Time.get_ticks_msec();

	if debug or damage.debug:
		print("[HEALTH DEBUG] %s by %s [%s]\n\t(damage reduction %s) (invincibility %s > %s) (tangible: %s - time: %s or priority: %s, time since ready %s)" % [
			self,
			damage,
			Time.get_ticks_msec(),
			damage_reduction,
			timeMark,
			immunityMark,
			not is_intangible(),
			timeMark > immunityMark,
			damage.immunityPriority > currentImmunityPriority,
			time_since_ready(),
		]);

	if frames_of_damage_delay > 0 and not damage.never_delayed and damage.origin != null:
		if !_is_delaying_damage():
			_delay_damage(damage, frames_of_damage_delay);
		return not is_intangible();
		
	if time_since_ready() < immunity_after_ready:
		return false;

	if not is_intangible():
		if timeMark > immunityMark:
			currentImmunityPriority = 0;
			return _do_damage(damage);
		elif damage.immunityPriority > currentImmunityPriority:
			currentImmunityPriority += 1;
			return _do_damage(damage);
		else:
			return false;

	return false;

var delay_tween:Tween;
func _is_delaying_damage()->bool:
	return delay_tween and delay_tween.is_valid();

func _delay_damage(damage:DamageData, frames:int):
	var self_health:Health = self;
	delay_tween = create_tween();
	delay_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);
	delay_tween.tween_interval(float(frames) / Engine.physics_ticks_per_second);
	delay_tween.tween_callback(func():
		if is_instance_valid(damage.origin) and \
				is_instance_valid(self_health) and \
				not damage.origin.is_queued_for_deletion():
			damage.never_delayed = true;
			damage(damage);
	);

func damage_kill(origin:Node3D = null, scores:bool = false)->void:
	var damage:DamageData = DamageData.new(currentAmount, origin, scores);
	_do_damage(damage);

func kill()->void:
	set_health(0);

func restore()->void:
	set_health(get_max_amount());

func is_intangible()->bool:
	return intangible or (intangible_if_dead and not is_alive());

func _find_feedbacks_recursive(node:Node3D, deepness:int, has_parent:bool, ignore:Array[String]):
	var was_parent:bool = has_parent;
	if node is MeshInstance3D:
		var feedbacker:Feedbacker = Feedbacker.new();
		feedbacker.mesh = node as MeshInstance3D;
		feedbacker.old_material = feedbacker.mesh.material_override; ## will override this in the first attack as to avoid bugs
		feedbacker.set_old_material = false; ## will override this in the first attack as to avoid bugs
		feedbacker.deepness = feedback_deepness - deepness;
		feedbacker.has_parent = has_parent;
		feedbacker.aabb_size = feedbacker.mesh.get_aabb().size;
		was_parent = true;
		_feedback_meshes.push_back(feedbacker);
	if node == null: return;
	if deepness > 0:
		for child in node.get_children():
			## skip if ignored
			var skip:bool = false;
			for ignore_name:String in ignore:
				if ignore_name.to_lower() in child.name.to_lower():
					skip = true;
			if skip:
				continue;

			## go to the next child
			if child is Node3D:
				_find_feedbacks_recursive(child as Node3D, deepness - 1, was_parent, ignore);


const ONE_FRAME_TIME:float = 1.0/60.0;
func _feedback_color(id:int, feedbacker:Feedbacker, damage:DamageData)->Tween:
	if feedbacker.mesh and _is_valid(feedbacker.mesh):
		if not feedbacker.set_old_material:
			feedbacker.set_old_material = true;
			feedbacker.old_material = feedbacker.mesh.material_override;

		feedbacker.mesh.material_override = DAMAGED_MATERIAL;

		var tree := get_tree();
		var frames:float = minf(1.2 + damage.amount * 4.0, 10);
		var mesh:MeshInstance3D = feedbacker.mesh;
		var old_material:Material = feedbacker.old_material;
		var t := mesh.create_tween();
		t.tween_interval(frames * ONE_FRAME_TIME);
		t.tween_callback(func():
			if _is_current_id(id) and _is_valid(mesh):
				mesh.material_override = old_material;
			);
		return t;
	else:
		return null;

func _feedback_scale(id:int, feedbacker:Feedbacker, damage:DamageData)->Tween:
	var target:Node3D = feedbacker.mesh;
	if _is_valid(target) and not feedbacker.has_parent:
		var tween:Tween = target.create_tween();
		if not feedbacker.set_original_scale:
			feedbacker.original_scale = target.scale;
			feedbacker.set_original_scale = true;
		target.scale = feedbacker.original_scale;
		tween.tween_interval(ONE_FRAME_TIME * maxf(feedbacker.deepness - 2, 0) * 3.0);
		tween.tween_callback(func():
			target.scale = feedbacker.original_scale + feedbacker.original_scale * (feedback_scale_multiplier);
			)
		tween.tween_property(target, "scale", feedbacker.original_scale, ONE_FRAME_TIME * (10 + damage.amount * 10 + feedbacker.deepness * 2))\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO);
		return tween;
	else:
		return null;


func _do_feedback(damage:DamageData):
	if not _is_feedbacking:
		_is_feedbacking = true;
		var id:int = _make_feedback_id();
		if hit_sfx:
			hit_sfx.post_event();
		if damage.frame_freeze_duration > 0 and TimeManager:
			TimeManager.frame_freeze(damage.frame_freeze_duration);
		if screen_shake_on_damaged:
			screen_shake_on_damaged.screen_shake();
		var evts:Array[Callable] = [];
		for feedbacker:Feedbacker in _feedback_meshes:
			evts.push_back(_do_feedback_single.bind(id, feedbacker, damage));
		await AwaitUtils.await_all(evts, self);
		_is_feedbacking = false;


var current_visual_tween:Dictionary[Feedbacker, Tween] = {};
func _do_feedback_single(id:float, feedbacker:Feedbacker, damage:DamageData):
	if current_visual_tween.has(feedbacker) and current_visual_tween[feedbacker].is_valid():
		current_visual_tween[feedbacker].kill();

	match visual_style:
		Style.SCALE_AND_COLOR:
			current_visual_tween[feedbacker] = get_parent().create_tween();
			current_visual_tween[feedbacker].set_parallel();
			var tcolor := _feedback_color(id, feedbacker, damage);
			if tcolor != null: current_visual_tween[feedbacker].tween_subtween(tcolor);
			var tscale := _feedback_scale(id, feedbacker, damage);
			if tscale != null: current_visual_tween[feedbacker].tween_subtween(tscale);
		Style.SCALE:
			current_visual_tween[feedbacker] = get_parent().create_tween();
			var tscale := _feedback_scale(id, feedbacker, damage);
			if tscale != null: current_visual_tween[feedbacker].tween_subtween(tscale);
		Style.COLOR:
			current_visual_tween[feedbacker] = get_parent().create_tween();
			var tcolor := _feedback_color(id, feedbacker, damage);
			if tcolor != null: current_visual_tween[feedbacker].tween_subtween(tcolor);
		Style.NONE:
			pass;


var _is_feedbacking:bool = false;
var _feedback_id:int = 0;
func _make_feedback_id()->int:
	_feedback_id += 1;
	return _feedback_id;
func _is_current_id(id:int)->bool:
	return id == _feedback_id;

func _do_damage(damage:DamageData)->bool:
	var amount:float = damage.amount;
	if is_invulnerable(damage): amount = 0.0;
	if amount > 0.0:
		amount = move_toward(amount, signf(amount), damage_reduction);
	var old_current_amount:float = currentAmount;
	currentAmount = clampf(currentAmount - amount, get_min_amount(), get_max_amount());
	set_immunity_mark(damage.immunityTime);
	if amount != 0:
		hit.emit(damage, self);
		hit_parameterless.emit();
		healthChange.emit(self);
		if not _check_death(damage):
			_do_feedback(damage);
		if damage.scores and Player.instance:
			Player.instance.just_did_damage(damage, old_current_amount);
	elif is_instance_valid(invulnerable_sfx):
		invulnerable_sfx.post_event()
	return true;

func set_immunity_mark(secondsSinceNow:float):
	immunityMark = Time.get_ticks_msec() + secondsSinceNow * 1000;

func is_alive() -> bool:
	if immortal:
		return true;
	else:
		return currentAmount > 0;

func is_invulnerable(damage_data:DamageData = null) -> bool:
	if damage_data and damage_data.overlap_invulnerablity:
		return false;
	if invulnerable:
		return true;
	elif invulnerable_if_off_screen and !invulnerable_if_off_screen.is_on_screen():
		return true;
	else:
		return false;

var wasAlive:bool;
func _check_death(damage:DamageData)->bool:
	var isAlive:bool = is_alive();
	if immortal:
		return false;
	if wasAlive != isAlive:
		wasAlive = isAlive;
		alive_change.emit(isAlive);
		if not isAlive:
			if debug:
				print("printing all connections for %s's %s" % [self.get_parent(), self]);
				for a in dead.get_connections():
					print(a);
				push_warning("%s is dead! [%s] (Debug is ON)" % [self.name, Engine.get_process_frames()])
				print("%s (%s hp) is dead! [%s]" % [self.name, currentAmount, Engine.get_process_frames()]);
			if frame_freeze_on_death and frame_freeze_on_death.value > 0 and TimeManager:
				TimeManager.frame_freeze(frame_freeze_on_death.value);
			if screen_shake_on_death:
				screen_shake_on_death.screen_shake();

			_emit_death_signal_delayed(damage, frames_until_send_death_signal, wait_until_send_death_signal);

			return true;
		else:
			revived_parameterless.emit();
			return false;
	else:
		return not isAlive;

func _emit_death_signal_delayed(damage:DamageData, frames:int, wait:float):
	var tree := get_tree();
	while frames > 0:
		await tree.physics_frame;
		frames -= 1;
	if wait > 0:
		await tree.create_timer(wait).timeout;

	if is_instance_valid(self):
		_emit_death_signal(damage);

	for deadStuff in to_queue_free_on_death:
		if deadStuff:
			deadStuff.queue_free();

func _emit_death_signal(damage:DamageData):
	dead.emit(self);
	dead_damage.emit(damage, self);
	dead_parameterless.emit();

func _is_valid(obj):
	return obj and is_instance_valid(obj) and not obj.is_queued_for_deletion();

func _to_string() -> String:
	return "%s (%s/%s HP)" % [
		owner.name if owner != null else name,
		get_health(),
		get_max_amount()]
