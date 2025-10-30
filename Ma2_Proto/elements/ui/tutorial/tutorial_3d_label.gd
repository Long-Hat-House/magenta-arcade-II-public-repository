extends Label3D

var alpha:float:
	get:
		return self.modulate.a;
	set(value):
		self.modulate.a = value;


func _ready() -> void:
	visible = false
	var flash := create_tween();
	flash.tween_property(self, "alpha", 0.0, 0.1);
	flash.tween_property(self, "alpha", 1, 0.75);
	flash.tween_interval(0.45);
	flash.set_loops(-1);


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free();
