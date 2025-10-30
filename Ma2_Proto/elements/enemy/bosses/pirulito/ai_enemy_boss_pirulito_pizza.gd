class_name Boss_Pirulito_Pizza extends Node3D

@export var explosion_scene:PackedScene;
@onready var ray_cast_3d:RayCast3D = $Body/RayCast3D
@onready var body:Node3D = $Body;
@onready var animation: AnimationPlayerProxy = $Body/Render/Pizza_Roboto;

func _ready():
	await get_tree().process_frame;
	ray_cast_3d.force_raycast_update();
	if ray_cast_3d.get_collider():
		body.global_position = ray_cast_3d.get_collision_point();
		
	await get_tree().create_timer(randf() * 0.25).timeout;
	animation.play(&"PIZZA_SHOOTER_DANCE")

func _on_health_dead(health):
	if explosion_scene:
		InstantiateUtils.InstantiateInTree(explosion_scene, self);
	queue_free();
	
func come_from_left():
	come_from(body.global_position + Vector3.LEFT * 8);
	
func come_from_right():
	come_from(body.global_position + Vector3.RIGHT * 8);

func come_from(origin:Vector3):
	var target:Vector3 = body.global_position;
	var height:float = target.y;
	body.global_position = Vector3(origin.x, height, origin.z);
	await get_tree().process_frame;
	var tween = create_tween();
	tween.tween_property(body, "global_position", target, 1.).set_delay(0.025 + randf() * 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);

func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free();
