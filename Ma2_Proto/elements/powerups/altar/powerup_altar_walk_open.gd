class_name AltarWalkAndOpen extends Altar

@export var direction:Vector3 = Vector3.BACK;

@export var speed_normal:float = 2.5;
@export var speed_slow:float = 0.75;
@export var speed_turbo:float = 12;
@export var speed_min_turbo:float = 3;
@export var acceleration_down:float = 15;
@export var acceleration_up:float = 6;
@onready var current_speed:float = speed_turbo;
@export var time_to_open:float = 0.8;
@export var time_to_open_random:float = 0.15;
@export var time_outside_screen:float = 2.0;
var in_screen:bool;

static var altars_in_game:Array[AltarWalkAndOpen];
static func run_away_all_altars(except:AltarWalkAndOpen):
	for altar:AltarWalkAndOpen in altars_in_game:
		if altar != except:
			altar.set_mode(MovementMode.Turbo);


enum MovementMode
{
	Normal,
	Turbo,
	Slow,
}

var currentMode:MovementMode = MovementMode.Normal;

var readied:bool;

func remove_carried():
	if carried:
		var gp := carried.global_position;
		carried.get_parent().remove_child(carried);
		self.get_parent().add_child(carried);
		carried.global_position = gp;

func set_mode(movementMode:MovementMode):
	currentMode = movementMode;
	if movementMode == MovementMode.Turbo:
		close(0)
		current_speed = max(current_speed, speed_min_turbo);

func _on_pressed(touch:Player.TouchData):
	super._on_pressed(touch);
	set_mode(MovementMode.Slow);
	run_away_all_altars(self);

func _on_released(touch:Player.TouchData):
	super._on_released(touch);
	altar_graphic.set_pressed(false);
	set_mode(MovementMode.Normal);

func _enter_tree():
	altars_in_game.append(self);

func _exit_tree():
	altars_in_game.erase(self);

func _ready():
	for child in get_children():
		if child is Node3D and child != body and child != altar_graphic:
			carry(child);
			break;
	npc_graphic.set_animation_npc(Graphic_NPC.NPCAnimation.Walk);
	readied = true;

func _process(delta:float):
	if entered_screen and time_to_open > 0:
		time_to_open -= delta;
		if time_to_open <= 0:
			altar_graphic.set_open(true);

	if not in_screen:
		time_outside_screen -= delta if entered_screen else delta * 0.2;
		if time_outside_screen < 0:
			queue_free();
		if entered_screen && !is_instance_valid(carried):
			queue_free()

func _physics_process(delta:float):
	super._physics_process(delta);
	body.velocity = direction * _get_current_speed(delta);
	body.move_and_slide();

func _get_current_speed(delta:float)->float:
	var target:float = _get_target_speed();
	if target > current_speed:
		current_speed += delta * acceleration_up;
	elif target < current_speed:
		current_speed -= delta * acceleration_down;
	return current_speed;

func _get_target_speed()->float:
	match currentMode:
		MovementMode.Normal:
			return speed_normal;
		MovementMode.Turbo:
			return speed_turbo;
		MovementMode.Slow:
			return speed_slow;
	return speed_turbo;

func _on_visible_on_screen_notifier_3d_screen_entered():
	time_to_open += randf_range(-time_to_open_random, time_to_open_random) * 0.5;
	entered_screen = true;
	in_screen = true;

func _on_visible_on_screen_notifier_3d_screen_exited():
	in_screen = false;
