extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var damage_area: DamageArea = $DamageArea

@export var vfx_hit:PackedScene;

func _enter_tree() -> void:
	zero_position.call_deferred()

func zero_position():
	position.y = 0

func cancel_damage():
	damage_area.queue_free();


func _on_damage_area_on_damaged_data(data:Health.DamageData, victim:Node3D) -> void:
	VFX_Utils.instantiate_vfx_set_for_damage(data, victim.global_position, vfx_hit);
