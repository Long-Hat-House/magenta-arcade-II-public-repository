extends Node

@export var random_first_time_down_min:float = 0.15;
@export var random_first_time_down_max:float = 2.0;
@export var time_down:float = 2.5;
@export var time_pre_shooting:float = 0.25;
@export var time_shooting:float = 1.25;
@export var time_post_shooting:float = 2.5;
@export var shot_interval:float = 0.15;
@export var proj:PackedScene;

@onready var animation_tree: AnimationTree = $AnimationTree

@onready var body: CharacterBody3D = $Area3D
@onready var health: Health = $Area3D/Health
@onready var graphic: Node3D = $Graphic
@onready var instantiate_place: Marker3D = %InstantiatePlace
@onready var spawn_area: SpawnArea = $SpawnArea
@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenEnabler3D
@onready var enemy_position:Node3D = $EnemyPosition

var outside_count:float;

var shooting_direction:Vector3;
var count:float;
var dead:bool;
var collision_layer:int;

var pressed:bool;

func _ready() -> void:
	collision_layer = body.collision_layer;

func _physics_process(delta: float) -> void:
	if shooting_direction != Vector3.ZERO and not dead:
		count -= delta;
		if count <= 0:
			shoot(-count);
			count += shot_interval;
		var wanted_direction = get_wanted_shoot_direction();
		var angle = shooting_direction.signed_angle_to(wanted_direction, Vector3.UP)
		shooting_direction = shooting_direction.rotated(Vector3.UP, signf(angle) * delta * 0.35);
		
	if !notifier.is_on_screen():
		outside_count += delta;
		if outside_count > 1:
			queue_free();

func set_pressed(pressed:bool):
	pass;

func set_active(active:bool):
	animation_tree.opened = active;
	graphic.scale = Vector3(1.2,1.4,1.2);
	body.collision_layer = collision_layer if active else 0;
	create_tween().tween_property(graphic, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);

func set_shooting(shooting:bool):
	animation_tree.shooting = shooting;
	if shooting:
		self.shooting_direction = get_wanted_shoot_direction();
	else:
		self.shooting_direction = Vector3.ZERO;
	
func get_wanted_shoot_direction()->Vector3:
	return -Player.get_closest_direction(instantiate_place.global_position);
	
func shoot(extra_delta:float):
	var shot:ProjEnemyBasic = InstantiateUtils.InstantiateInTree(proj, instantiate_place);
	shot.global_basis = Basis.looking_at(shooting_direction);
	shot.speedMultiplier = 1.65;

func _on_health_dead(health: Health) -> void:
	set_active(false);
	Tokenizer.free_token("mole", self);
	enemy_position.queue_free(); ##So it cant be aimed anymore
	dead = true;
	spawn_area.do_spawn_default();
		

func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	pass


func _on_visible_on_screen_enabler_3d_screen_entered() -> void:
	if !is_node_ready(): await ready;
	routine();
		
func routine():	
	set_active(false);
	await get_tree().create_timer(randf_range(random_first_time_down_min, random_first_time_down_max)).timeout;
	if !is_instance_valid(self):
		return;
	
	while notifier.is_on_screen() and health.is_alive():
		if pressed:
			while pressed:
				await get_tree().process_frame;
				if not is_instance_valid(self): return;
			await get_tree().create_timer(time_down).timeout;
			if not is_instance_valid(self): return;	
				
		set_active(true);
		await get_tree().create_timer(time_pre_shooting).timeout;
		if not is_instance_valid(self): return;	
		await Tokenizer.await_next_token_and_pick("mole", self, 1);
		if not is_instance_valid(self): return;	
		set_shooting(true);
		await get_tree().create_timer(time_shooting).timeout;
		if not is_instance_valid(self): return;	
		set_shooting(false);
		Tokenizer.free_token("mole", self);
		await get_tree().create_timer(time_post_shooting).timeout;
		if not is_instance_valid(self): return;
		set_active(false);
		await get_tree().create_timer(time_down).timeout;
		if not is_instance_valid(self): return;	



func _on_pressable_pressed() -> void:
	pressed = true;

	set_active(false);
	set_shooting(false);


func _on_pressable_released() -> void:
	pressed = false;
