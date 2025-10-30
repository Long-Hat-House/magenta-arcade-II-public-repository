extends StaticBody3D

#@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var weak_point_health: Health = $WeakPointHealth
@onready var collision: CollisionShape3D = $CollisionShape3D

func set_active(active:bool):
	visible = active;
	collision.disabled = !active;
	if !active:
		position.y -= 10;

func revive():
	weak_point_health.restore();
