class_name Projectile_IvoSpirit extends LHH3D

@onready var graphic: Node3D = $Graphic

@export var create_time_min:float = 3.0;
@export var create_time_max:float = 6.0;
@export var warning_time:float = 0.65;
@export var possession_time_min:float = 0.4;
@export var possession_time_max:float = 1.0;

@export var sfx_create:WwiseEvent;
@export var sfx_warning:WwiseEvent;
@export var sfx_heal:WwiseEvent;
@export var sfx_attack:WwiseEvent;

@onready var border: MeshInstance3D = $Graphic/Border

signal created;
signal warned;


var _percentage_creation:float:
	get:
		return _percentage_creation;
	set(value):
		_percentage_creation = value;
		graphic.scale = Vector3.ONE * lerpf(0.001, 1, value);
	
var tweening:Tween;
func tween_to_something(something:Node3D, on_finish:Callable):
	tweening = create_tween();
	var original_position:Vector3 = self.global_position;
	tweening.tween_method(func(value:float):
		if is_instance_valid(something):
			global_position = original_position.lerp(something.global_position, value);
		, 0.0, 1.0, randf_range(possession_time_min, possession_time_max)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	tweening.tween_callback(func():
		if is_instance_valid(something):
			on_finish.call();
		self.queue_free();
		);

func self_create():
	var t := create_tween();
	_percentage_creation = 0;
	var time:float = randf_range(create_time_min, create_time_max);
	_percentage_creation = 0.45 * 0.75;
	t.tween_callback(sfx_create.post.bind(graphic));
	t.tween_property(self, "_percentage_creation", 0.45, time * 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	t.tween_property(self, "_percentage_creation", 1, time * 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);
	t.parallel().tween_subtween(warning(warning_time * 0.5)).set_delay(time * 0.75 - warning_time);
	t.tween_callback(func():
		created.emit();
		)
		
func heal_feedback():
	sfx_heal.post(graphic);		
		
func attack_feedback(where:Node3D = null):
	if where == null: where = graphic;
	sfx_attack.post(where);
		
func warning(time:float)->Tween:
	var t := create_tween();
	t.tween_callback(func():
		sfx_warning.post(graphic);
		warned.emit();
		)
	t.tween_method(func(value:float):
		border.set_instance_shader_parameter("Light", Color.MAGENTA.lerp(Color.TRANSPARENT, value));
		, 0.0, 1.0, time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);
	return t;
