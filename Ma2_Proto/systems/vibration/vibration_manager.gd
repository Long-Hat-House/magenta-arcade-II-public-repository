class_name VibrationManager extends Node

static var instance:VibrationManager;

@export var enabled:bool = true;

class VibrationID:
	var id:int;
	var priority:int;

	func _init(pid:int, ppriority:int) -> void:
		id = pid;
		priority = ppriority;

func _ready() -> void:
	instance = self;

var vibrations:Array[VibrationID] = [];
var current_vibration:int;

func get_new_id(priority:int)->VibrationID:
	current_vibration += 1;
	return VibrationID.new(current_vibration, priority);

func get_current_priority()->int:
	return vibrations.reduce(func(accum:int, current:VibrationID):
		return maxi(accum, current.priority);
		, -9999)

static func vibrate(priority:int, duration_ms:int = 500, amplitude:float = -1.0):
	if instance and is_instance_valid(instance):
		instance.vibrate_single(priority, duration_ms, amplitude);

func vibrate_single(priority:int = 0, duration_ms:int = 500, amplitude:float = -1.0):
	if not enabled:
		return;


	if priority < get_current_priority():
		return;
	if amplitude == 0.0 or duration_ms == 0:
		return;


	var this_id = get_new_id(priority);
	vibrations.push_back(this_id);
	current_vibration = priority;

	if amplitude < 0: amplitude = -1.0;
	Input.vibrate_handheld(duration_ms, amplitude);
	current_vibration = priority;

	await get_tree().create_timer(float(duration_ms) / 1000.0).timeout;
	vibrations.erase(this_id);
