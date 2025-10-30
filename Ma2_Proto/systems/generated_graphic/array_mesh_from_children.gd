@tool
class_name ArrayMeshFromChildren
extends MeshInstance3D

@export var global_id:String;

static var global_meshes:Dictionary = {};

@export var material:Material:
	get:
		return material;
	set(value):
		material = value;
		self.mesh.surface_set_material(0, material);

func _ready()-> void:
	if global_id and global_meshes.has(global_id):
		self.mesh = global_meshes[global_id];
	else:
		_rebuild();
		if not global_id.is_empty():
			global_meshes[global_id] = self.mesh;
	self.mesh.surface_set_material(0, material);


func _rebuild():

	var vertices:PackedVector3Array = [];
	for child in get_children():
		var node3D:Node3D = child as Node3D;
		if node3D:
			vertices.push_back(node3D.position)

	var arrays:Array = [];
	arrays.resize(Mesh.ARRAY_MAX);
	arrays[Mesh.ARRAY_VERTEX] = vertices;

	var arr_mesh:ArrayMesh = ArrayMesh.new();
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays);
	arr_mesh.surface_set_material(0, material);

	self.mesh = arr_mesh;

func _notification(what: int) -> void:
	if not Engine.is_editor_hint(): return;
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_rebuild();
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_rebuild();
