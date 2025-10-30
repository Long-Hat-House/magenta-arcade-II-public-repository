extends StaticBody3D


func _on_wall_health_dead_parameterless() -> void:
	queue_free();
