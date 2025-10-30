class_name Enemy_FakeIvoStatue extends LHH3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var pressable: Pressable = $Dancer/Pressable
@onready var graphic_ivo_estatua: Graphic_Statue_Ivo = $"Dancer/Graphics - AnimationPivot_X/Graphics - AnimationPivot_Y/Graphics - AnimationTumbler/Graphics - Rotation Death Dance/Graphics - AnimationShake/graphic_ivo_estatua"
@onready var instantiate_place:Node3D = %"Shot Origin";
@onready var enabler: VisibleOnScreenEnabler3D = $Dancer/Enabler
@onready var health: Health = $Dancer/StaticBody3D/Health
@onready var body: StaticBody3D = $Dancer/StaticBody3D
@onready var high_contrast:AccessibilityHighContrastObject = $"Dancer/Graphics - AnimationPivot_X/Graphics - AnimationPivot_Y/Graphics - AnimationTumbler/Graphics - Rotation Death Dance/Graphics - AnimationShake/graphic_ivo_estatua/AccessibilityHighContrastObject"



@export var dancer:Node3D;
var dancer_initial_position:Vector3;
var dance_force:float = 0;
@export var dance_velocity:float;
@export var dance_frequency:Vector2 = Vector2(1,2);
@export var dance_amplitude:Vector2;

@export var projectile:PackedScene;
@export var angle_between:float;
@export var shoot_direction_base:Vector3 = Vector3.BACK;
@export var shoot_direction_random_angle:float = 0;
@export var check_activation_health_percentage:float = 0.8;

@export var sfx_shoot:AkEvent3D;

signal activated_dead;

enum Style
{
	## Force this statue to be always off
	FORCE_OFF,
	## Force this statue to be always on
	FORCE_ON,
	## This statue will be on IF it is picked by the algorithm
	RANDOM,
}

@export var style:Style;

var shoot_delay:float = 0;
var activated:bool;

static var total_alive_statues:Array[Enemy_FakeIvoStatue];

func _ready() -> void:
	graphic_ivo_estatua.set_eyes(false, 0);
	dancer_initial_position = dancer.position;

func _physics_process(delta: float) -> void:
	if activated and is_instance_valid(health) and health.is_alive():
		shoot_delay -= delta;
		while shoot_delay < 0:
			shoot_delay += 2; ## Interval
			shoot(shoot_direction_base.rotated(
					Vector3.UP, 
					randf_range(-0.5, 0.5) * deg_to_rad(shoot_direction_random_angle)), 
					0.5, 
					3, 
					angle_between
				);
	if dance_force > 0 and is_instance_valid(health) and health.is_alive():
		_death_dance_process(delta, dancer, dance_force, dance_velocity, dance_frequency, dance_amplitude, Vector3.ZERO);

func _exit_tree() -> void:
	if activated:
		total_alive_statues.erase(self);
		activated = false;

func is_on()->bool:
	match style:
		Style.FORCE_ON:
			return true;
	return false;

func crazy_statue_behaviour(delta:float):
	pass
	
static var possible_statues:Array[Enemy_FakeIvoStatue];

static func turn_on_possible_statues(amount:int, on_dead:Callable = Callable()):
	possible_statues.shuffle();
	print("[STATUES] Turning on %s statues of %s" % [amount, possible_statues]);
	while amount > 0 and possible_statues.size() > 0:
		amount -= 1;
		var statue = possible_statues.pop_back() as Enemy_FakeIvoStatue;
		if statue and is_instance_valid(statue):
			statue.style = Style.FORCE_ON;
			statue.activated_dead.connect(on_dead, CONNECT_ONE_SHOT);
			statue.check_if_alive();

func _on_enabler_screen_entered() -> void:
	if style == Style.RANDOM:
		possible_statues.append(self);


func _on_enabler_screen_exited() -> void:
	if style == Style.RANDOM:
		possible_statues.erase(self);

func activate():
	if not activated:
		if high_contrast:
			high_contrast.change_group(&"enemy");
		total_alive_statues.append(self);
		health.damage_reduction = 0;
		_show_activation();
		if dance_amplitude.length_squared() > 0 and dance_frequency.length() > 0:
			create_tween().tween_property(self, "dance_force", 1.0, 3.0);
		activated = true;
	
func _show_activation():
	var t:= create_tween();
	t.set_parallel()
	t.tween_callback(sneeze.bind(false)).set_delay(1.0);
	t.tween_method(func(value:float):
		graphic_ivo_estatua.set_wave_shake_default(value, Vector3(1.5,0,0.75))
		, 0.5, 1.0, 1.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	t.tween_method(func(value:float):
		graphic_ivo_estatua.set_eyes(value > 0, value)
		, 0.0, 1.0, 1.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
	
	

func _on_pressable_pressed() -> void:
	if is_on():
		activate();
	
func is_in_screen():
	return enabler.is_on_screen();	
	
func can_shoot()->bool:
	return not pressable.is_pressed and is_in_screen();
		
func shoot(direction:Vector3, duration:float, amount:int = 1, angle_between_shots:float = 30):
	angle_between_shots = deg_to_rad(angle_between_shots);
	sfx_shoot.post_event();
	if can_shoot():
		direction.y = 0;
		
		var range:float = (amount - 1) * angle_between_shots
		var min_direction:Vector3 = direction.rotated(Vector3.UP, -range * 0.5)
		for index:int in range(amount):
			var dirThis:Vector3 = min_direction.rotated(Vector3.UP, angle_between_shots * index)
			_shoot_once(dirThis);
			
		sneeze(false);
		tilt(Vector3.UP.slerp(-direction, 0.2), duration * 0.2, duration * 0.8);
	else:
		shake(0.5, 0.2);
	

func _shoot_once(direction:Vector3):
	var shot:Node3D = InstantiateUtils.InstantiateInTree(projectile, instantiate_place, Vector3.ZERO, false, true);
	print("Fake Big Follower Shooting %s" % projectile);
	shot.global_basis = Quaternion(Vector3.FORWARD, direction.normalized()) as Basis;
	shot.basis = shot.basis.orthonormalized();
	shot.lock_in_vector(self, Vector3.BACK, true);

var dd_count:float = 0;
var dd_z:Vector3 = Vector3.BACK;
var dd_d2:Vector3;
var dd_pos:Vector3;
func _death_dance_process(delta:float, dancer:Node3D, force:float, velocity:float, frequency:Vector2, amplitude:Vector2,  offset_position:Vector3,):
	dd_count += delta * velocity;

	var old_global_position:Vector3 = dancer.global_position;
	dancer.position = dancer_initial_position + \
			force * offset_position + \
			force * Vector3(cos(dd_count * frequency.x) * amplitude.x, 0.0, sin(dd_count * frequency.y) * amplitude.y);
	var old_dd:Vector3 = dd_pos;
	dd_pos = Vector3(-sin(dd_count) * amplitude.x, 0.0, cos(dd_count) * amplitude.y) * force;

	var d2:Vector3 = dancer.global_position - old_global_position;
	var d2_dd:Vector3 = (dd_pos - old_dd);
	
	dd_d2 += d2;
	dd_d2 = dd_d2.move_toward(Vector3.ZERO, 60 * delta);
	
	var y:Vector3 = Vector3.UP - dd_d2 * 5;
	var z:Vector3 = Vector3.BACK.slerp(d2_dd, 0.3 * sin(Vector3.BACK.angle_to(d2_dd)));
	dd_z = dd_z.move_toward(z, delta * 0.5);
	var x:Vector3 = y.cross(z);
	
	print("[STATUE FAKE] Basis is %s %s %s because distance is %s (dif %s)" % [x, y, z, d2, dd_d2]);
	dancer.basis = dancer.basis.slerp(Basis(x,y,dd_z).orthonormalized(), 0.35);

func shake(duration:float, shakeMaxDistance:float):
	graphic_ivo_estatua.shake(duration, shakeMaxDistance);
	
func sneeze(big:bool):
	if big:
		graphic_ivo_estatua.sneeze_big();
	else:
		graphic_ivo_estatua.sneeze_small();
		
func tilt(where:Vector3, duration_in:float, duration_out:float):
	graphic_ivo_estatua.tilt(where, duration_in, duration_out);

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	#queue_free();
	pass;


func _on_health_dead(health: Health) -> void:
	if is_on():
		var eyes := create_tween();
		eyes.tween_method(func(value:float):
			graphic_ivo_estatua.set_eyes(value > 0, value)
			, 1.5, 0.0, 1.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
		
	if activated:
		activated = false;
		total_alive_statues.erase(self);
		activated_dead.emit();
		
	anim.play(&"fall");
	await anim.animation_finished;
	
	possible_statues.erase(self);
	body.queue_free();
	pressable.queue_free();
	
	var t:= create_tween();
	t.tween_property(self, "position", Vector3.DOWN * 4, 4).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC);
	t.tween_callback(queue_free);

var tried_activating:bool;
func _on_health_hit_parameterless() -> void:
	if not tried_activating and health.get_health_percentage() < check_activation_health_percentage:
		tried_activating = true;
		if is_on():
			activate();
		else:
			health.kill();
			
func check_if_alive():
	if health.get_health_percentage() < check_activation_health_percentage and is_on():
		activate();
