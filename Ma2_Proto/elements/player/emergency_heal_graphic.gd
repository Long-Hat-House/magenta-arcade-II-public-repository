extends Task

@export var object_scene:PackedScene;
@export var speed_max:float = 10;
@export var acceleration:float = 50;
@export var decay:float = 30;

var object:EmergencyHealingElement;

var _object_target_offset:Vector3 = Vector3(0, 2,-3)
var speed:Vector3;

func _process(delta: float) -> void:
	if is_instance_valid(object):
		var _target_position:Vector3 = Player.get_medium_position() + _object_target_offset
		var dist:Vector3 = _target_position - object.position;
		speed = speed.move_toward(Vector3.ZERO, decay * delta);
		speed += dist * acceleration * delta;
		speed = speed.limit_length(speed_max);

		object.position += speed * delta;


func _on_emergency_heal_healing_step() -> void:
	if is_instance_valid(object):
		object.step();

func _on_emergency_heal_healing_start() -> void:
	if !is_instance_valid(object):
		object = object_scene.instantiate();
		add_child(object);

	object.global_position = Player.get_medium_position();
	speed = Vector3.ZERO;
	object.begin();

func _on_emergency_heal_healing_decayed() -> void:
	if object:
		var _obj = object
		object = null
		await _obj.bad_end();
		_obj.queue_free()

func _on_emergency_heal_healing_completed() -> void:
	if object:
		var _obj = object
		object = null
		await _obj.good_end();
		_obj.queue_free()

func _on_val_updated(val:float):
	if object:
		object.set_val(val)
