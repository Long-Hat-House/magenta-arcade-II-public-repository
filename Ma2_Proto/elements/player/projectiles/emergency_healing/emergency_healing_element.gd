class_name EmergencyHealingElement extends LHH3D

const small_scale:Vector3 = Vector3.ONE * 0.01;

@export var sprite_3d:Sprite3D
@export var fill_feedback:Node3D

var tween:Tween;
var sprite_color:Color;

func _ready() -> void:
	sprite_color = sprite_3d.modulate;

func begin():
	scale = small_scale;

	if tween and tween.is_running(): tween.kill();
	tween = create_tween();
	tween.tween_property(self, "scale", Vector3.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);

	await tween.finished;

func bad_end():
	if tween and tween.is_running(): tween.kill();
	tween = create_tween();
	tween.tween_property(self, "scale", small_scale, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);

	await tween.finished;

func good_end():
	if tween and tween.is_running(): tween.kill();
	tween = create_tween();
	tween.tween_property(self, "position:y", 22.0, 1.5).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART);

	await tween.finished;

func step():
	scale = Vector3.ONE * 0.75;
	sprite_3d.modulate = Color.GHOST_WHITE;

	if tween and tween.is_running(): tween.kill();
	tween = create_tween();
	tween.tween_property(self, "scale", Vector3.ONE, 1.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	tween.parallel().tween_property(sprite_3d, "modulate", sprite_color, 1.5);
	await tween.finished;

func set_val(val:float):
	fill_feedback.scale = Vector3.ONE.lerp(Vector3.ONE*1.2, val)
