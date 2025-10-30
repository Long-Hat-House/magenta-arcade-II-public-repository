extends Node3D

@export var _vfx_scene:PackedScene
@export var _instantiate_offset:Vector3 = Vector3.UP

func _on_health_hit_parameterless() -> void:
	InstantiateUtils.InstantiateInSamePlace3D(_vfx_scene, self, _instantiate_offset, true, true)
