class_name EmergencyHeal
extends Node

@onready var player:Player = $".."

@export var fingers_needed:int = 2;
@export var hp_or_less:int = 1;
@export var time_needed:float = 5;
@export var steps:int = 5;
@export var time_decay:float = INF;
@export var trans_heal:Tween.TransitionType;
@export var ease_heal:Tween.EaseType;
@export var trans_decay:Tween.TransitionType;
@export var ease_decay:Tween.EaseType;

var current_healing_process:float:
	get:
		return current_healing_process;
	set(value):
		current_healing_process = value;
		healing_change_total.emit(value)
var current_healing_step:int:
	get:
		return current_healing_step;
	set(value):
		if value > current_healing_step:
			healing_step.emit();
		current_healing_step = value;


signal healing_start;
signal healing_change_total(process:float);
signal healing_step;
signal healing_completed;
signal healing_decayed;

func _ready() -> void:
	player.just_holded_any.connect(add_finger);
	player.just_released_after.connect(remove_finger);

func add_finger():
	if trying_to_heal() and !is_healing():
		tween_heal();

func remove_finger():
	if !trying_to_heal() and is_healing():
		tween_release();

func can_heal()->bool:
	return Player.instance.currentState.emergency_heal_level > 0 and player.hp <= hp_or_less

func trying_to_heal()->bool:
	return can_heal() and Player.instance.currentTouches.size() >= fingers_needed

func is_healing()->bool:
	return curr_tween and curr_tween.is_running();

var curr_tween:Tween;

func cancel_tween():
	if curr_tween and curr_tween.is_running():
		curr_tween.kill();

func tween_release():
	cancel_tween();
	if time_decay == INF or time_decay == 0:
		current_healing_process = 0.0;
		current_healing_step = 0;
		healing_decayed.emit();
	else:
		curr_tween = create_tween();
		curr_tween.tween_property(self, "current_healing_process", 0.0, time_decay)\
				.set_ease(ease_decay).set_trans(trans_decay);
		curr_tween.parallel().tween_property(self, "current_healing_step", 0, time_decay)\
				.set_ease(ease_decay).set_trans(trans_decay);
		curr_tween.tween_callback(func():
			cancel_tween()
			healing_decayed.emit()
			)

func tween_heal():
	cancel_tween();
	curr_tween = create_tween();
	curr_tween.tween_callback(healing_start.emit);
	curr_tween.tween_property(self, "current_healing_process", 1.0, time_needed)\
				.set_ease(ease_decay).set_trans(trans_decay);
	curr_tween.parallel().tween_property(self, "current_healing_step", steps, time_needed)\
				.set_ease(ease_decay).set_trans(trans_decay);
	curr_tween.tween_callback(func():
		HUD.instance.make_screen_add(MA2Colors.GREENISH_BLUE, MA2Colors.blend_transparency(MA2Colors.BUTTON_ICON, 0), 0.5, Tween.EASE_IN, Tween.TRANS_CUBIC);
		player.heal(1, false);
		cancel_tween()
		healing_completed.emit();
		);
