extends Node

@export var enemy:PackedScene;
@export var enemyStartFunction:String;
@export var enemyStartExtraParameters:Dictionary;
@onready var level = $"../level_base"


func _ready()->void:
	ObjectPool.make_singleton(self);

func _unhandled_input(event:InputEvent):
	if event is InputEventMouseButton:
		var pos:Vector3 = get_touch_position_to_world_position(event.position);
		print("generating enemy in %s" % pos);
		var newEnemy = ObjectPool.instantiate(enemy);
		var enemyNode = newEnemy.node as Node3D;
		level.add_child(enemyNode);
		enemyNode.global_position = pos;
		if enemyNode.has_method(enemyStartFunction):
			enemyNode.call(enemyStartFunction, pos, Vector3.ZERO);
		
func get_touch_position_to_world_position(touchPosition:Vector2)->Vector3:
	var rayLength := 100.0;
	var currentCamera := get_viewport().get_camera_3d();
	var groundPlane:Plane = Plane(Vector3.UP, Vector3.ZERO);
	var from:Vector3 = currentCamera.project_ray_origin(touchPosition);
	var toRelative:Vector3 = currentCamera.project_ray_normal(touchPosition) * rayLength;
	
	return groundPlane.intersects_ray(from, toRelative);
	
