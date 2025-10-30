class_name Element_StreetBarrier extends GameElement

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var body: StaticBody3D = $StaticBody3D

func set_active(active:bool):
	var t := create_tween();
	t.tween_property(mesh, "position", body.position, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);
	await t.finished;
	body.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED;

func _on_health_hit(damage: RefCounted, health: Health) -> void:
	print("hit stuff")
	pass # Replace with function body.
