class_name AI_Roboto_Copter extends Node3D

@export var velocityLine:float;
@export var line:ChildLine3D;
@export var offsetLinePosition:float;
@export var vfxOnDie:PackedScene;
@export var time_outside_screen:float = 2.0;
var left_screen_count:float;

var body:CharacterBody3D;
var linePos:float;
var score:ScoreGiver;
var offsetPosition:Vector3;
var tiltNow:Vector3 = Vector3.DOWN;
var lineValue:Array[Vector3];

@onready var notifier: VisibleOnScreenNotifier3D = $Body/VisibleOnScreenNotifier3D
@onready var graphic:Graphic_RobotoCopter = $Body/Render/robotocopter_graphic as Graphic_RobotoCopter

static var copter_groups:int;

static func cmd_make_copters_quick(lvl:Level, copter_scenes:Array[PackedScene], copters:Array[int], where_vec3:Callable, dir:Vector3, distances:Array[float], group:String = "", offset:float = 2)->Level.CMD:

	return Level.CMD_Callable.new(func():
		var pos:Vector3 = where_vec3.call();
		make_copters_quick(lvl, copter_scenes, copters, pos, dir, distances, group, offset);
	);

static func make_copters_quick(lvl:Level, copter_scenes:Array[PackedScene], copters:Array[int], pos:Vector3, dir:Vector3, distances:Array[float], group:String = "", offset:float = 2):
	var line := make_line_value(distances, pos, dir);
	var total_offset:float = 0;
	
	copter_groups += 1
	var score_group_id:String = "copters_direct_"+str(copter_groups)
	var score_group:ScoreManager.ScoreGroup
	if !score_group_id.is_empty():
		score_group = ScoreManager.instance.get_score_group(score_group_id, ScoreManager.SCORE_INFO_GROUP_COPTER)

	for copter_index:int in copters:
		if copter_index < 0:
			total_offset -= offset;
			continue;
			
		copter_index = clampi(copter_index, 0, copter_scenes.size() - 1);

		var copter:AI_Roboto_Copter = lvl.objs.create_object(copter_scenes[copter_index], group, pos);
		copter.set_line_values(line, total_offset);
		total_offset -= offset;
		if score_group:
			score_group.add_obj_with_giver_inside(copter)
	if score_group:
		score_group.set_group_ready()


## Make a line with quick numbers. Number means distance THEN turn. Negative number means turn right, positive is turn left. After it all ends, the line ends at 100 distance more to leave screen.
## Example: [3, 3, -2, -2, 3]
## Go 3, then turn right, go 3 then turn right, go 2 then turn left, go 2 then turn left, go 3 then turn right, then go forever.
static func make_line_value(distances:Array[float], initial_pos:Vector3, initial_dir_normalized:Vector3)->Array[Vector3]:
	var dir:Vector3 = initial_dir_normalized;
	var pos:Vector3 = initial_pos;

	var arr:Array[Vector3] = [initial_pos];

	for value in distances:
		var length:float = absf(value);
		var sign:float = signf(value);

		pos += dir * length;
		arr.push_back(pos);
		dir = dir.rotated(Vector3.UP, PI * 0.5 * sign);

	pos += dir * 100;
	arr.push_back(pos);

	#print("[ROBOTO COPTER] With %s made %s (start %s, dir %s)" % [distances, arr, initial_pos, initial_dir_normalized]);

	return arr;

func _ready():
	body = $Body as CharacterBody3D;
	offsetPosition = body.position;
	#print("[COPTER] %s Readied at %s %s" % [self, global_position, Engine.get_physics_frames()]);

func _physics_process(delta:float):
	linePos += velocityLine * delta;
	var destination:Vector3;
	if is_instance_valid(line):
		destination = line.get_position_in_line(linePos + offsetLinePosition) + offsetPosition;
		if (linePos + offsetLinePosition) > line.get_line_length():
			vanish();
	elif lineValue and lineValue.size() > 0:
		destination = ChildLine3D.get_position_in_position_array(lineValue, linePos + offsetLinePosition) + offsetPosition;
		if (linePos + offsetLinePosition) > ChildLine3D.get_position_array_length(lineValue):
			vanish();
	else:
		destination = body.global_position;
	#print("%s moving from %s to %s [%s]" % [self, body.global_position, destination, destination - body.global_position]);
	body.velocity = (destination - body.global_position);

	#tiltNow = tiltNow.slerp(-Vector3.DOWN * 0.3 + Vector3.BACK * 0.7, delta * 0.5);
	var vel:Vector3 = -body.velocity;
	#vel.z = 0;
	tiltNow = tiltNow.slerp(3*Vector3.DOWN + vel.normalized(), delta*5);
	tiltNow = tiltNow.normalized()
	graphic.set_tilt(tiltNow);

	#body.move_and_slide();
	var collision := body.move_and_collide(body.velocity);
	if collision:
		Health.Damage(collision.get_collider(), Health.DamageData.new(1, self));

	if not notifier.is_on_screen():
		left_screen_count += delta;
		if left_screen_count > time_outside_screen:
			queue_free.call_deferred();

func set_line_values(line_value:Array[Vector3], offset:float = 0.0):
	self.lineValue = line_value;
	self.line = null;
	self.offsetLinePosition = offset;

func set_line(line:ChildLine3D, asValue:bool = true, offset:float = 0.0):
	if asValue:
		self.lineValue = line.get_position_values();
		self.line = null;
	else:
		self.line = line;
	self.offsetLinePosition = offset;

func _on_health_dead(health):
	explode();

func vanish():
	self.queue_free();

func explode():
	if vfxOnDie:
		InstantiateUtils.InstantiateInTree(vfxOnDie, body);
	vanish();


var amount_bodies_evade:int;

func add_evade_body(n:Node3D):
	amount_bodies_evade += 1;
	check_evade_body();

func remove_evade_body(n:Node3D):
	amount_bodies_evade -= 1;
	check_evade_body();

var evade_tween:Tween;
var evaded:bool;
func check_evade_body():
	var evaded_now:bool = amount_bodies_evade > 0;
	if evaded_now != evaded:
		if evade_tween and evade_tween.is_valid():
			evade_tween.kill();

		evade_tween = create_tween();
		evade_tween.tween_property(graphic, "position:y", 1.1 if evaded_now else 0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);


		evaded = evaded_now;

func _on_enemy_not_touch_me_body_entered(b: Node3D) -> void:
	if body != b:
		add_evade_body(b);
	#print("[COPTER] %s added %s -> amount %s" % [self, b, amount_bodies_evade]);


func _on_enemy_not_touch_me_body_exited(b: Node3D) -> void:
	if body != b:
		remove_evade_body(b);
	#print("[COPTER] %s removed %s -> amount %s" % [self, b, amount_bodies_evade]);


func _on_enemy_not_touch_me_area_entered(area: Area3D) -> void:
	add_evade_body(area);
	#print("[COPTER] %s added area %s -> amount %s" % [self, area, amount_bodies_evade]);


func _on_enemy_not_touch_me_area_exited(area: Area3D) -> void:
	remove_evade_body(area);
	#print("[COPTER] %s removed area %s -> amount %s" % [self, area, amount_bodies_evade]);
