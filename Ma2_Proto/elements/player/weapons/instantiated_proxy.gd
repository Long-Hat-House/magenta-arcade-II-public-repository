class_name InstantiatedProxy extends Marker3D

signal instantiated(proj:Node3D);

func instantiated_here(proj:Node3D):
	instantiated.emit(proj);
