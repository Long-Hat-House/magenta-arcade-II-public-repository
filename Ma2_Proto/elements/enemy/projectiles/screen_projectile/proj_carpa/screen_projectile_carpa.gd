extends Node
@onready var graphic_normal: Graphic_Carpa = $"../TheProjectile/roboto_carpa"
@onready var graphic_dead: Node3D = $"../TheProjectile/Node3DShaker/roboto_carpa_dead"
@onready var shaker: Node3DShaker = $"../TheProjectile/Node3DShaker"
@onready var dead_target: Marker3D = $"../TheProjectile/dead_target"
@onready var parent: ScreenProjectile = $".."

@export var scale_increase:float = 0.2;


func _on_screen_projectile_carpa_progress_raw(progress: float) -> void:
	graphic_normal.set_fear(progress);


func _on_screen_projectile_carpa_finished() -> void:
	graphic_normal.visible = false;
	graphic_dead.visible = true;
	
	
	graphic_dead.scale = Vector3.ONE + (Vector3(1, 1, 0) * scale_increase)
	shaker.shake_amplitude = 0.05;
	var t := graphic_dead.create_tween();
	t.tween_property(shaker, "shake_amplitude", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	t.parallel().tween_property(graphic_dead, "scale:x", 1.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	t.parallel().tween_property(graphic_dead, "scale:y", 1.0, 0.35).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
	t.tween_method(func(value:float):
		graphic_dead.transform = Transform3D.IDENTITY.interpolate_with(dead_target.transform, value);
		,0.0, 1.0, 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_delay(0.05);
	await t.finished;
	
	parent.queue_free();
	
