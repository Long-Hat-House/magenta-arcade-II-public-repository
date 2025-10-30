extends Node3D

@export var rotate_z:bool
@export var conversion:float = 1
@export var multiplier:float = 1

@export var to_move:Node3D

func _ready() -> void:
	await get_tree().process_frame
	HUBLanesSystem.instance.lane_movement_ratio_updated.connect(_movement_updated)

func _movement_updated(val:float):
	if !to_move: to_move = self
	if rotate:
		to_move.rotation = Vector3(0,deg_to_rad(val**conversion*multiplier),0)
	else:
		to_move.position.x = val*conversion*multiplier
