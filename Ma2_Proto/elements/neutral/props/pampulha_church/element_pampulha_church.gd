class_name Element_PampulhaChurch extends Node3D

signal damaged;
signal destroyed;
signal grounded;

@export var amount_damage_to_destroy:float = 3;
@export var damage_cap_before_challenge:float = 0.1;
@export var smokes:Array[CPUParticles3D];

@onready var pampulha_church: Node3D = $Node3DShaker/pampulha_church

@onready var health_leftmost: Health = $"Area3D Leftmost/Health Leftmost"
@onready var health_second: Health = $"Area3D Second/Health Second"
@onready var health_third_big: Health = $"Area3D Third big/Health Third Big"
@onready var health_right: Health = $"Area3D Right/Health Right"

@onready var shaker: Node3DShaker = $Node3DShaker
var shake:float:
	get:
		return shaker.shake_amplitude;
	set(value):
		shaker.set_shake_amplitude(value);

var damage:float;

var in_challenge:bool;
var was_destroyed:bool;
var was_grounded:bool;
var invincible:bool;

func make_invincible():
	invincible = true;

func _get_damaged_general(d: Health.DamageData, h:Health):
	if not invincible:
		damage += d.amount;
	if !in_challenge: ##cap the damage
		damage = minf(damage, damage_cap_before_challenge);
	shake_building(0.15, 1.2);
	damaged.emit();
	
	if get_damaged_number() >= amount_damage_to_destroy:
		destroy_routine();
	
func get_damaged_number()->float:
	return damage;
	
func get_remaining_hp()->float:
	return amount_damage_to_destroy - get_damaged_number();

func _ready() -> void:
	set_smoke(false);

func _on_health_leftmost_hit(damage: Health.DamageData, health: Health) -> void:
	_get_damaged_general(damage, health);


func _on_health_second_hit(damage: Health.DamageData, health: Health) -> void:
	_get_damaged_general(damage, health);


func _on_health_third_big_hit(damage: Health.DamageData, health: Health) -> void:
	_get_damaged_general(damage, health);


func _on_health_right_hit(damage: Health.DamageData, health: Health) -> void:
	_get_damaged_general(damage, health);
	
var shake_tween:Tween;
func shake_building(force:float, duration:float)->Tween:
	if shake_tween and shake_tween.is_running():
		shake_tween.kill();
	shake_tween = create_tween();
	shake_tween.tween_property(self, "shake", force, duration * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	shake_tween.tween_property(self, "shake", 0, duration * 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);
	return shake_tween;
	
func destroy_routine(delay:float = 1.5, duration:float = 2.0):
	if not was_destroyed and not invincible:
		set_smoke(true);
		was_destroyed = true;
		shake_building(0.25, duration * 2);
		destroyed.emit();
		await get_tree().create_timer(delay).timeout;
		var destroy_tween:Tween = create_tween();
		destroy_tween.tween_property(pampulha_church, "position:y", -10, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
		await destroy_tween.finished;
		grounded.emit();
		was_grounded = true;
		await get_tree().create_timer(1).timeout;
		set_smoke(false);


func _on_pressable_pressed() -> void:
	set_pressed_tween(Vector3(1.1, 0.7, 1.1), 0.1, Tween.TRANS_BACK);


func _on_pressable_released() -> void:
	set_pressed_tween(Vector3(1,1,1), 0.4, Tween.TRANS_ELASTIC);

var pressed_tween:Tween;
func set_pressed_tween(scale:Vector3, time:float, trans:Tween.TransitionType):
	if pressed_tween and pressed_tween.is_running():
		pressed_tween.kill();
	
	pressed_tween = create_tween();
	pressed_tween.tween_property(pampulha_church, "scale", scale, time).set_ease(Tween.EASE_OUT).set_trans(trans);

	
func start_challenge():
	in_challenge = true;
	
func is_destroyed()->bool:
	return was_destroyed;
	
func is_grounded()->bool:
	return was_grounded;
	
func set_smoke(on:bool):
	for smoke in smokes:
		smoke.emitting = on;
