class_name Enemy_Chaser extends AI_Base

@export var speed:float = 5.5;
@export var acceleration:float = 7;
@export var min_distance_from_others:float = 2;
@export var max_distance_from_others:float = 4;
@export var avoidance_force:float = 4;
@export var explosion_vfx:PackedScene;
@export var attack_explosion:PackedScene;
@export var warning_time:float = 2;
@export var neutral_position_screen_offset:Vector3 = Vector3.BACK * 3;
@export var high_contrast_group_when_warning := &"danger";
var currentSpeed:Vector3;

@onready var accessibility_high_contrast_object: AccessibilityHighContrastObject = $AccessibilityHighContrastObject
@onready var graphic:Graphic_Perseguidora = $roboto_bomba_perseguidora
@onready var damage_area: DamageArea = $DamageArea

@export_category("Chaser Audio")
@export var _sfx_warning_start:WwiseEvent
@export var _sfx_warning_stop:WwiseEvent

enum State
{
	None,
	Idle,
	Search
}

var _is_warning:bool = false

var state:State;
var player:Player;
var bodyHeight:float;
var sineT:float;

func _ready():
	_change_state(State.Idle);
	player = Player.instance;
	bodyHeight = graphic.position.y;
	sineT = 0;
	health.intangible = true;
	damage_area.enabled = false;
	await get_tree().create_timer(0.1).timeout;
	health.intangible = false;
	damage_area.enabled = true;

static var all_perseguidores:Array = [];
func _enter_tree():
	all_perseguidores.append(self);

func _exit_tree():
	all_perseguidores.erase(self);
	if _sfx_warning_stop: _sfx_warning_stop.post(self)

func _change_state(newState:State):
	if newState != state:
		state = newState;
		match state:
			State.Idle:
				graphic.set_open(false);
			State.Search:
				graphic.set_open(true);

func _process(delta:float):
	graphic.position.y = bodyHeight + sin(sineT) * 0.08;
	sineT += delta * (16 if state == State.Search else 4);

func _physics_process(delta: float) -> void:
	if player:
		_change_state(State.Search if player.currentTouches.size() > 0 else State.Idle)
	else:
		_change_state(State.Idle)

	# follow player
	var wantedSpeed:Vector3;
	if state == State.Search:
		var nearestFinger:Vector3 = player.get_closest_position(self.global_position, true);
		wantedSpeed = (nearestFinger - self.global_position).normalized() * speed;
	elif state == State.Idle:
		var center = LevelCameraController.instance.get_pos() + neutral_position_screen_offset
		var direction = center - self.global_position
		if direction.length() > 4:
			wantedSpeed = direction.normalized() * speed * 0.75;
		else:
			wantedSpeed = Vector3.ZERO
	else:
		wantedSpeed = Vector3.ZERO;

	# evade each other
	var avoidance:Vector3 = Vector3.ZERO;
	var amountChasers:int = 0;
	for chaser in all_perseguidores:
		if chaser != self:
			var distance:Vector3 = chaser.global_position - self.global_position;
			var distanceLength = distance.length();
			var avoidLength = 1 - inverse_lerp(min_distance_from_others, max_distance_from_others, clamp(min_distance_from_others, max_distance_from_others, distanceLength));
			avoidance += -distance.normalized() * avoidLength * avoidance_force;
			amountChasers += 1;
	if amountChasers > 0:
		avoidance /= amountChasers;
	wantedSpeed += avoidance;

	currentSpeed += LevelCameraController.instance.last_physics_step_movement;
	currentSpeed = currentSpeed.move_toward(wantedSpeed, acceleration * delta)

	self.position += currentSpeed * delta;

func explode():
	if _sfx_warning_stop: _sfx_warning_stop.post(self)
	if explosion_vfx:
		InstantiateUtils.InstantiateInSamePlace3D(explosion_vfx, self);
	queue_free();

func attack():
	if attack_explosion:
		InstantiateUtils.InstantiateInSamePlace3D(attack_explosion, self);

func warn():
	accessibility_high_contrast_object.change_group(high_contrast_group_when_warning)
	graphic.warning()

func warn_then_explode():
	if _is_warning: return
	_is_warning = true
	warn();
	if _sfx_warning_start: _sfx_warning_start.post(self)
	await get_tree().create_timer(warning_time).timeout;
	attack();
	explode();

func set_speed(s:Vector3):
	currentSpeed = s;

func _on_health_dead(health):
	explode();

func _on_health_hit(damage, health):
	Health.DamageFeedback(graphic as Node, damage);

func _on_explosion_area_area_entered(area):
	if !health.intangible:
		warn_then_explode();

func _on_explosion_area_body_entered(body):
	if !health.intangible:
		warn_then_explode();

func _on_damage_area_on_damaged():
	if !health.intangible:
		attack();
		explode();
