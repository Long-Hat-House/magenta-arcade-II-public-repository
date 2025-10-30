@tool
class_name Altar_Revolution_Circle extends LHH3D

const MARKER = preload("res://elements/editor/marker/editor_simple_marker.tscn")
const ALTAR = preload("res://elements/powerups/altar/graphic_altar.tscn")
const POWERUP_ALTAR_TWEENABLE = preload("res://elements/powerups/altar/powerup_altar_tweenable.tscn")
@onready var circle: ChildrenInCircle = $Circle

@export var id:StringName;
@export var circle_radius:float;
@export var circle_arc_min:float = 0;
@export var circle_arc_max:float = 360;
@export var circle_multiplier:Vector2 = Vector2.ONE;
@export var circle_amount:int = 0;
@export var circle_offset:float;
var markers:Array[Node];

@export var altar_scene:PackedScene = load("res://elements/powerups/altar/powerup_altar_tweenable.tscn");
@export var spawn_on_ready:bool = true;
@export var spawn_every_angle:bool;
@export var velocity_angle:float;

@export var normal_button_scene:PackedScene;
@export var extra_buttons:Array[PackedScene];

@export var debug:bool;

signal altar_destroyed;


func _ready() -> void:
	if !Engine.is_editor_hint():
		for mark in markers:
			mark.queue_free();
		markers.clear();

		if spawn_on_ready:
			var arr_buttons = _get_button_scene_arr();

			var arr_inst:Array[Node3D] = []
			arr_inst.assign(arr_buttons.map(func(x):
				if x:
					return x.instantiate();
				else:
					return null;
				));
			add_altars(arr_inst, deg_to_rad(circle_arc_min), deg_to_rad(circle_arc_max));

	circle.radius = circle_radius;
	circle.circ_multiplier = circle_multiplier;
	circle.walk_min_arc = deg_to_rad(circle_arc_min);
	circle.walk_max_arc = deg_to_rad(circle_arc_max);
	circle.offset_angle = circle_offset;


func _get_button_scene_arr()->Array[PackedScene]:
	var arr_buttons:Array[PackedScene] = extra_buttons.duplicate();
	while arr_buttons.size() < circle_amount:
		arr_buttons.push_back(normal_button_scene);

	arr_buttons.shuffle();
	return arr_buttons;

func start_spawning():
	var t = create_tween();
	var distance:float = absf(deg_to_rad(circle_arc_max) - deg_to_rad(circle_arc_min));
	var arr_buttons = _get_button_scene_arr();
	t.tween_callback(func():
		print("adding altar %s" % [arr_buttons.back()]);
		add_altar(arr_buttons.pop_back().instantiate());
		)
	t.tween_interval((distance / (circle_amount)) / deg_to_rad(absf(velocity_angle)));
	t.set_loops(circle_amount);

func change_markers(num:int):
	var old_size = markers.size();
	if old_size > num:
		while markers.size() > num:
			markers[markers.size() - 1].queue_free();
			markers.remove_at(markers.size() - 1)
	else:
		while markers.size() < num:
			var inst:Node3D = ALTAR.instantiate();
			add_child(inst);
			markers.append(inst);


	var angles = NumberUtils.get_equally_separated_numbers(circle_arc_min, circle_arc_max, num + 1);
	for i in range(num):
		markers[i].position = ChildrenInCircle.get_circle_position(circle_radius, deg_to_rad(angles[i]) + circle_offset, circle_multiplier);

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		change_markers(circle_amount);

func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint():
		circle.walk_elements(delta * deg_to_rad(velocity_angle))

func add_altar(button:Node3D):
	circle.add_element(_make_altar(button), circle_arc_min, true);
	if debug:
		print("[REVOLUTION CIRCLE] %s added %s to circle. %s -> circles: %s" % [id, button, circle.get_child_count(), circle.get_angles_string()]);

func add_altars(buttons:Array[Node3D], arc_min:float = 0, arc_max:float = 2 * PI):
	buttons.assign(buttons.map(_make_altar));
	circle.add_elements_equally_spaced(buttons, arc_min, arc_max);
	if debug:
		print("[REVOLUTION CIRCLE] %s added %s to circle. %s -> circles: %s" % [id, buttons, circle.get_child_count(), circle.get_angles_string()]);

func _make_altar(button:Node3D)->Altar:
	var altar := POWERUP_ALTAR_TWEENABLE.instantiate();
	altar.id = id;
	altar.carry(button);
	altar.destroyed.connect(altar_destroyed.emit, CONNECT_ONE_SHOT);
	return altar;
