extends Node3D

@onready var mesh = get_node("MeshInstance3D") if has_node("MeshInstance3D") else null
@onready var damage_area = $DamageArea
@export var onColor:Color;
@export var offColor:Color;
@export var duration:float = 0.5;
@export var duration_collision_multiplier:float = 0.25;
@export var rotated_copies_shape:int = 1;
@onready var shape:CollisionShape3D = $DamageArea/CollisionShape3D
@onready var explosion:Graphic_Little_Explosion = $explosion

var madeMaterial:bool = false;

var _materialColor:float;
var materialColor:float:
	set(value):
		if mesh:
			if not madeMaterial:
				mesh.material_override = mesh.get_active_material(0).duplicate();
			var mat:Material = mesh.material_override as Material;
			#print("[EXPLOSION] setting color %s to %s" % [value, mat]);
			if mat:
				mat.albedo_color = offColor.lerp(onColor, value);
		_materialColor = value;
	get:
		return _materialColor;

func _ready():
	if damage_area:
		damage_area.monitoring = false;
		damage_area.monitorable = false;
		damage_area.enabled = false;
	if rotated_copies_shape > 1:
		for i in range(rotated_copies_shape - 1):
			var newShape:CollisionShape3D = shape.duplicate();
			shape.get_parent().add_child(newShape);
			var angle:float = (i + 1) * (360/rotated_copies_shape);
			newShape.rotation = Vector3(shape.rotation.x, angle, shape.rotation.z);
			newShape.position = Quaternion.from_euler(Vector3(0,angle,0)) * shape.position;
			#print("[EXPLOSION] making shape with rotation y %s" % newShape.rotation.y);


# Called when the node enters the scene tree for the first time.
func _enter_tree():
	materialColor = 1;
	if not is_node_ready(): await self.ready;
	await get_tree().physics_frame;
	if damage_area: 
		deactivate_collision(duration * duration_collision_multiplier);
	await explosion.play();
	await get_tree().physics_frame;
	materialColor = 0;
	ObjectPool.repool.call_deferred(self);


func deactivate_collision(delay:float):
	damage_area.monitoring = true;
	damage_area.monitorable = true;
	damage_area.enabled = true;
	await get_tree().create_timer(delay).timeout;
	damage_area.monitoring = false;
	damage_area.monitorable = false;
	damage_area.enabled = false;
