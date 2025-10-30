class_name AI_Tucano extends CharacterBody3D

@export var speed:float = 12;
@export var curve_direction:Vector3;
@export var curve_angle_multiplier:float;

@export var height:float = 1;

@export var vfx:PackedScene;

@onready var instantiate_place: Node3D = $InstantiatePlace
@onready var out_of_screen_warning_origin: VisibleOnScreenNotifier3D = $OutOfScreenWarningOrigin


var in_screen:bool;
@export var out_of_screen_count:float = 1.0;

@export var smoke:PackedScene;
@export var needs_screen_to_spawn:bool = false;
@export var smoke_spawn_distance:float = 0.75;
@export var smoke_spawn_distance_variance:float = 0.25;
var distance_count:float;

var path:Path3D;
var path_length:float;
var path_count:float;

signal left_screen;

func _ready() -> void:
	await get_tree().process_frame;
	global_position += Vector3.UP * height;


func damage()->Health.DamageData:
	return Health.DamageData.new(1, self, false, false);


func get_current_speed()-> float:
	return speed;


func move_and_damage(movement:Vector3):
	var collision:KinematicCollision3D = move_and_collide(movement);
	if collision and collision.get_collider():
		for i in range(collision.get_collision_count()):
			Health.Damage(collision.get_collider(i), damage());

func move(movement:Vector3):
	position += movement;


func _physics_process(delta: float) -> void:
	#path
	if path and path_count <= path_length:
		path_count += get_current_speed() * 0.5 * delta;
		global_transform = get_path_transform(path_count);
	else:
		#curve
		if curve_direction != Vector3.ZERO and curve_angle_multiplier != 0:
			var angle:float = global_basis.z.signed_angle_to(curve_direction, Vector3.UP);
			angle *= delta * curve_angle_multiplier;
			basis = basis.rotated(Vector3.UP, angle);


		#walk
		var distance:float = get_current_speed() * delta;
		move_and_damage(basis.z.normalized() * distance);

		if smoke and ((needs_screen_to_spawn and in_screen) or not needs_screen_to_spawn):
				distance_count -= distance;
				while distance_count < 0.0:
					LevelObjectsController.instance.create_object(smoke, "", instantiate_place.global_position);
					#print("%s created smoke in %s" % [self, instantiate_place.global_position]);
					distance_count += smoke_spawn_distance + (randf() - 0.5) * smoke_spawn_distance_variance;

	if not in_screen:
		out_of_screen_count -= delta;
		if out_of_screen_count < 0:
			left_screen.emit();
			vanish();


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	in_screen = true;

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	in_screen = false;

func set_path3d(path:Path3D):
	self.path = path;
	self.path_count = 0;
	self.path_length = path.curve.get_baked_length();
	self.global_transform = get_path_transform(0)

func get_path_transform(count:float)->Transform3D:
	var tr:Transform3D = path.curve.sample_baked_with_rotation(count);
	tr.basis.x *= -1;
	tr.basis.z *= -1;
	return path.global_transform * tr;

func vanish():
	queue_free(); ##count wont work if reused

func destroy():
	if vfx:
		InstantiateUtils.InstantiateInTree(vfx, self);

func _on_health_dead(health: Health) -> void:
	destroy();
	vanish();
