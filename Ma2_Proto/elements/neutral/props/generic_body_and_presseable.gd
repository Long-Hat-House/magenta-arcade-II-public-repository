class_name GenericBodyAndPresseable extends AnimatableBody3D

@onready var pressable:Pressable = $"Pressable_Kill"
@onready var area:Area3D = $Pressable_Kill/Area3D;
@onready var generic_explosion:GenericExploder = %Exploder;
@onready var health:Health = $Health;
@onready var pressable_kill: Pressable_Kill = $Pressable_Kill

@export var explanation:String = "Put the shapes and the node3Ds for the explosion under this!"
@export var explosion_vfx:PackedScene;
### Use the suffix _* on child nodes, where * is the index of the vfx you want.
@export var extra_vfx:Array[PackedScene];
@export var life_value:float = 1;
@export var on_kill_queue_free:Array[Node];
@export var intangible:bool = false;
@export var press_is_kill:bool = true;
@export var generic_tumbler:GenericTumbler;
@export var exploding_pre_time:float = 0.15;
@export var exploding_sink_y_distance:float = 2;
@export var death_generic_tumbler_model_shake_strength:float = 0.5;

@export var visual_feedback_of_health:Array[Node3D];
@export var visual_feedback_deepness:int = 5;

signal hit;
signal try_hit;
signal pressed;
signal unpressed;
signal dead;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var shapes:Array[CollisionShape3D] = []
	var explosionNodes:Array[Node3D] = []

	if visual_feedback_of_health.size() > 0 and (health.feedback == null or health.feedback.size() <= 0):
		health.feedback = visual_feedback_of_health;
		health.feedback_deepness = visual_feedback_deepness;
		health.prepare_visual_feedback();

	for child in get_children():
		if child is CollisionShape3D:
			shapes.push_back(child as CollisionShape3D);
		elif child is PhysicsBody3D:
			if child is GenericBodyAndPresseable:
				var gbp:GenericBodyAndPresseable = child as GenericBodyAndPresseable;
				if gbp.generic_explosion:
					generic_explosion.extra_explosions.push_back(gbp.generic_explosion);
			continue;
		elif child is VisibleOnScreenEnabler3D:
			continue;
		elif child != pressable and child != generic_explosion and child is Node3D:
			explosionNodes.push_back(child as Node3D);

	##copy shapes to area
	var shape_id = area.create_shape_owner(area);
	for shape:CollisionShape3D in shapes:
		var copy:CollisionShape3D = shape.duplicate();
		area.add_child(copy);
		area.shape_owner_add_shape(shape_id, copy.shape)

	##move rest to explosion
	if explosion_vfx:
		for node in explosionNodes:
			var gp:Vector3 = node.global_position;
			node.get_parent().remove_child(node);
			generic_explosion.add_child(node);
			node.global_position = gp;
		generic_explosion.assign_health(health);
		generic_explosion.explosion_VFX = explosion_vfx;
		generic_explosion.extra_vfx = extra_vfx;
		generic_explosion.pre_time_exploding = exploding_pre_time;
	else:
		generic_explosion.queue_free();

	if press_is_kill:
		pressable_kill.health_to_kill = health;
	else:
		pressable_kill.health_to_kill = null;
	health.set_max_health(life_value);
	health.intangible = intangible;

	if generic_tumbler and health:
		generic_tumbler.assign_health(health);


func _on_pressable_kill_pressed() -> void:
	pressed.emit();


func _on_pressable_kill_released() -> void:
	unpressed.emit();


func _on_health_try_damage_parameterless() -> void:
	try_hit.emit();


func _on_health_hit_parameterless() -> void:
	hit.emit();


func _on_health_dead_parameterless() -> void:
	if is_instance_valid(generic_tumbler) and is_instance_valid(generic_tumbler.to_tumble):
		var tumbler:Node3D = generic_tumbler.to_tumble;
		var original_position:Vector3 = tumbler.position;
		var t := tumbler.create_tween();
		t.tween_method(func(value:float):
			tumbler.position = original_position \
					+ Vector3.DOWN * value \
					+ 0.5 * VectorUtils.rand_vector3_range(-death_generic_tumbler_model_shake_strength, death_generic_tumbler_model_shake_strength)
			, 0.0, exploding_sink_y_distance, exploding_pre_time).set_ease(Tween.EASE_OUT);
	dead.emit();


func _on_exploder_exploded() -> void:
	for killed in on_kill_queue_free:
		killed.queue_free();
