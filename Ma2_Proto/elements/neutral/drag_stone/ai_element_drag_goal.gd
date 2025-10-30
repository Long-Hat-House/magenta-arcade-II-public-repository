extends Node3D

@export var call_duration:float = 0.25;
@export var space_duration:float = 0.75;
@export var clock_in_duration:float = 0.25;

@onready var damage_area: DamageArea = $DamageArea

func _ready() -> void:
	damage_area.position.y += 1000;

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name.to_lower().contains("drag"):
		body.get_parent().stopped = true;
		var t:= body.create_tween()
		t.tween_property(body, "global_position", global_position, space_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO);
		t.tween_property(body, "position", Vector3.UP * 0.25, clock_in_duration * 0.5).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
		t.tween_property(body, "position", Vector3.DOWN * 0.45, clock_in_duration * 0.5).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);
		t.tween_callback(func():
			var t2 := body.create_tween();
			t2.tween_property(body, "rotation:y", PI, 2);
			t2.set_loops(-1);
			)
		t.parallel().tween_callback(func():
			if is_instance_valid(damage_area):
				damage_area.global_position = LevelCameraController.instance.get_pos();
				await get_tree().create_timer(0.05).timeout;
				if is_instance_valid(damage_area):
					damage_area.queue_free();
			).set_delay(call_duration)
