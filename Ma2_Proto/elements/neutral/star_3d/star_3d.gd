class_name Star3D extends Node3D

@export var _particles:CPUParticles3D
@export var _graphic:Node3D

func set_star_on(val:bool):
	_graphic.visible = val
	_particles.emitting = val
