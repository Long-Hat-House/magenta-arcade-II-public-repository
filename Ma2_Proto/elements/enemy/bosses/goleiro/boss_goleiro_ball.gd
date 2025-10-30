class_name Boss_Goleiro_Ball extends CharacterBody3D

@onready var pres_ball:Node3D = $PressScale
@onready var elas_ball:Node3D = $PressScale/Elasticity
@onready var dir_ball: Node3D = $PressScale/Elasticity/Direction
@onready var rot_ball: Node3D = $PressScale/Elasticity/Direction/Rotation
@onready var health: Health = $Health
@onready var graphic: Graphic_Ball = $PressScale/Elasticity/Direction/Rotation/ball
@onready var pressable: Pressable = $Pressable
@onready var pressable_feedback: PressableFeedback = $PressableFeedback
var gave_pressable_feedback:bool;

@onready var fall_sfx: AkEvent3D = $SFX/FallSFX
@onready var bounce_sfx: AkEvent3D = $SFX/BounceSFX
@onready var player_hit_sfx: AkEvent3D = $SFX/PlayerHitSFX
@onready var boss_hit_sfx: AkEvent3D = $SFX/BossHitSFX


@export_category("Gameplay Ball")
@export var reset_time:float = 1;

@export var initial_speed:float = 2;
@export var extra_hit_speed:float = 5;
@export var extra_hit_speed_time:float = 1;
var hit_tween_boost:Tween;
var boost_value:float;

@export var speed_collision_add:float = 0.25;
@export var speed_collision_boost:float = 1;
@export var screen_energy_weight:float = 3;
@export var normal_energy_weight:float = 1;

@export var add_velocity_when_hit_enemy:Vector3 = Vector3.FORWARD * 3;

@export var player_touch_time:float = 0.5;

@export_category("Feedback Ball")
@export var speed_to_rot:float = 5;
@export var deform_value:float = 1;
var deform_tween:Tween;


var active:bool;
var player_hit_last:int;

enum State{
	None,
	Untouchable,
	Hittable,
	Damaging,
}

var state:State = State.None:
	get:
		return state;
	set(value):
		if state != value:
			state = value;
			match state:
				State.Untouchable:
					health.invulnerable = true;
					graphic.set_emission_active(false);
					#barriguinha.mesh.surface_get_material(0).set("albedo_color", _test_normal_color);
					return;
				State.Damaging:
					health.restore();
					health.invulnerable = false;
					graphic.set_emission_active(true);
					#barriguinha.mesh.surface_get_material(0).set("albedo_color", _test_fire_color);
					return;
				State.Hittable:
					if !gave_pressable_feedback:
						gave_pressable_feedback = true;
						pressable_feedback.do_effect();
					health.invulnerable = true;
					graphic.set_emission_active(false);
					#barriguinha.mesh.surface_get_material(0).set("albedo_color", _test_normal_color);
					return;
					

signal goal_enemy;
signal goal_allied;

signal hit_enemy;
signal hit_boss;
signal hit_player;
signal collided;

signal started;

func get_speed()->Vector3:
	if active:
		return ball_velocity + boost_value * ball_velocity.normalized();
	else:
		return Vector3.ZERO;
	
var ball_direction:Vector3;
		
func _enforce_ball_direction_process():
	if not ball_direction.is_zero_approx():
		dir_ball.global_basis = Basis.looking_at(ball_direction, Vector3.UP, true);
		dir_ball.basis = dir_ball.basis.orthonormalized();
		
var ball_velocity:Vector3:
	get:
		return ball_velocity;
	set(value):
		value.y = 0;
		ball_velocity = value;
		if value != Vector3.ZERO:
			ball_direction = value.normalized();
			
var speed:float:
	get:
		return ball_velocity.length();
	set(value):
		ball_velocity = ball_velocity.normalized() * value;
		
var reset_index:int = 0;

func stop():
	ball_direction = Vector3.FORWARD;
	ball_velocity = Vector3.ZERO;
	state = State.Hittable;
	
func start(to_boss:bool):
	state = State.Hittable;
	var direction:Vector3 = Vector3.FORWARD if to_boss else Vector3.BACK;
	ball_velocity = direction * initial_speed;
	active = true;
	started.emit();
	
func _ready() -> void:
	state = State.Untouchable;

func _process(delta: float) -> void:
	var speed := get_speed();
	var rotation_velocity:float = speed.length();
	rot_ball.basis = rot_ball.basis.rotated(Vector3.RIGHT, delta * rotation_velocity * speed_to_rot)
	_enforce_ball_direction_process();
	
func is_in_time(stamp:int, time:float):
	return (float(get_now_stamp() - stamp) / 1000.0) < time;
	
func get_now_stamp()->int:
	return Time.get_ticks_msec();

func _physics_process(delta: float) -> void:
	var travel:Vector3 = get_speed() * delta;
	var original_travel := travel;
	var collision:KinematicCollision3D = move_and_collide(travel, true);
	if collision and not state == State.Untouchable:
		var len:int = collision.get_collision_count();
		if len > 0:
			var normal:Vector3 = Vector3.ZERO;
			var count:int = 0;
			var touches:Array[Object] = [];
			var boss:Boss_Goleiro = null;
			for collision_index:int in range(len):
				var collider:Node = collision.get_collider(collision_index) as Node;
				if collider is PhysicsBody3D and \
				not collider.is_in_group(&"projectile"):
					var this_normal:Vector3 = collision.get_normal(collision_index);
					this_normal.y = 0;
					this_normal = this_normal.normalized();
					var pt:PlayerToken = collider as PlayerToken;
					if pt:
						print("[BB] PLAYER TOUCH BALL time:%s pressable:%s [%s]" % [
							is_in_time(player_hit_last, player_touch_time),
							pressable.is_pressed,
							Engine.get_physics_frames()
							]);
						if is_in_time(player_hit_last, player_touch_time):
							continue;
						#if pressable.is_pressed:
							#continue;
						player_hit_last = get_now_stamp();
						hit_player.emit();
						if state == State.Damaging:
							Health.Damage(pt, Health.DamageData.new(1, self, false, false))
						var energy:Vector3 = normal_energy_weight * pt.get_energy(PlayerToken.EnergyType.Energy) +\
								screen_energy_weight * pt.get_energy(PlayerToken.EnergyType.ScreenEnergy);
						energy /= (screen_energy_weight + normal_energy_weight);
						if energy.length_squared() > 0:
							print("[BB] PLAYER HIT BALL [%s]" % Engine.get_physics_frames());
							hit(energy, is_power(pt));
							return;
						else:
							print("[BB] PLAYER BOUNCE BALL [%s]" % Engine.get_physics_frames());
							#this_normal.x = 0;
							#this_normal.y = 0;
							#this_normal.z = signf(this_normal.z);
							ball_velocity = ball_velocity.limit_length(maxf(ball_velocity.length() * 0.5, initial_speed * 0.55));
					else:
						boss = collider.get_parent() as Boss_Goleiro;
						if collider.is_in_group("enemy_position"):
							if not boss:
								ball_velocity += add_velocity_when_hit_enemy;
								var h:Health = Health.FindHealth(collider);
								if h:
									hit_enemy.emit();
									h.kill();
					normal += this_normal;
					count += 1;
					touches.push_back(collider);
					print("[BB] ball collided with %s %s [%s]" % [collider, this_normal, Engine.get_physics_frames()]);
			print("[BB] resolve: ball collided with %s (%s) things, normal %s [%s]" % [count, collision.get_collision_count(), normal, Engine.get_physics_frames()]);
			if count > 0:
				normal /= count;
				normal.y = 0;
				if should_collide(normal):
					collide(normal.normalized());
					travel = Plane.PLANE_XZ.project(collision.get_travel());
					travel += get_speed().normalized() * collision.get_remainder().length() * delta;
			if boss:
				hit_boss.emit();
				#ball_velocity = normal.normalized() * ball_velocity.length();
				var vel := boss.get_current_velocity();
				add_velocity(vel * delta * 8);
				travel += vel * delta;
				#print("[BOSS] hit boss -> to %s (vel %s) and travel is %s while normal is %s and travelling direction was %s [%s]" % [vel, ball_velocity, travel, normal, original_travel, Engine.get_physics_frames()]);
	position += travel;
		
func set_active(is_active:bool):
	active = is_active;		
	
func set_damaging():
	state = State.Damaging;
		
func goal(allied:bool):
	active = false;
	feedback_goal(allied);
	if allied:
		goal_allied.emit();
	else:
		goal_enemy.emit();

func should_collide(normal:Vector3):
	return ball_velocity.angle_to(normal) >= (PI * 0.5);

func collide(normal:Vector3):
	print("[BB] collision! vel %s -> %s + %s 'normal %s' [%s]" % [ball_velocity, ball_velocity.bounce(normal), speed_collision_add, normal, Engine.get_physics_frames()]);
	ball_velocity = ball_velocity.bounce(normal);
	add_velocity_length(speed_collision_add);
	feedback_collision(ball_velocity.normalized(), false);
	collided.emit();
	
	
	
func set_ball_velocity(vel:Vector3):	
	ball_velocity = vel;
	
func add_velocity(vel:Vector3):
	ball_velocity += vel;
	
func add_velocity_length(length_add:float):
	ball_velocity = ball_velocity.normalized() * (ball_velocity.length() + length_add);
	
	
func hit(direction:Vector3, power:bool):
	active = true;
	var np:bool = not power;
	var min_power:float = 0.9 if np else 1.5;
	var max_power:float = 1.5 if np else 3.0;
	var force:float = remap(direction.length(), 0, 1, initial_speed * min_power, initial_speed * max_power);
	ball_velocity = force * direction.normalized();
	add_boost();
	add_velocity_length(speed_collision_boost if power else speed_collision_add);
	feedback_collision(direction, power);
	
func add_boost():
	if hit_tween_boost and hit_tween_boost.is_valid():
		hit_tween_boost.kill();
	hit_tween_boost = create_tween();
	boost_value = extra_hit_speed;
	hit_tween_boost.tween_property(self, "boost_value", 0.0, extra_hit_speed_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	
	
func is_power(pt:PlayerToken):
	var data := Player.instance.find_touch_data_from_token(pt);
	for touch in Player.instance.currentTouches:
		if touch != data:
			if touch.instance.get_energy().length_squared() < 0.1:
				return true;
	return false;


func feedback_collision(direction:Vector3, power:bool):
	if !power:
		direction *= 0.5;
	deform(direction);
	bounce_sfx.post_event();
	
func deform(direction_amount:Vector3):
	if deform_tween and deform_tween.is_running():
		deform_tween.kill();
	deform_tween = create_tween();
	deform_tween.tween_method(func(value:float):
		var basis:Basis = Basis();
		basis.x = Vector3.RIGHT * (1 - value * direction_amount.x);
		basis.y = Vector3.UP * (1 + value * (direction_amount.x + direction_amount.z));
		basis.z = Vector3.FORWARD * (1 - value * direction_amount.z);
		elas_ball.basis = basis;
		,1.0, 0.0, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	
func feedback_goal(allied:bool):
	speed = 0.25;
	pass;

func _on_health_dead(health: Health) -> void:
	state = State.Hittable;


func _on_pressable_pressed_player(touch: RefCounted) -> void:
	press_feedback(
		Vector3(1.5, 0.25, 1.5),
		Vector3(1.05, 0.5, 1.05),
		0.25,
		Tween.TRANS_QUINT
	)


func _on_pressable_released_player(touch: RefCounted) -> void:
	press_feedback(
		Vector3(0.75, 1.5, 0.75),
		Vector3(1,1,1),
		0.85,
		Tween.TRANS_ELASTIC
	)
	
var press_tween:Tween;
func press_feedback(from:Vector3, to:Vector3, duration:float, trans:Tween.TransitionType):
	if press_tween and press_tween.is_running():
		press_tween.kill();
	pres_ball.scale = from;
	press_tween = pres_ball.create_tween();
	press_tween.tween_property(pres_ball, "scale", to, duration).set_ease(Tween.EASE_OUT).set_trans(trans);

func feedback_fall():
	fall_sfx.post_event();
