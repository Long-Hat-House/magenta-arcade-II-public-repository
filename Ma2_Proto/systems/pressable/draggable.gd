class_name Draggable extends Pressable

@onready var walk_together: Node3D = $WalkTogether
@onready var shape_cast_3d: ShapeCast3D = $"Drag Body/ShapeCast3D"
@export var body:PhysicsBody3D;
@export var stopped:bool;
@export var decay_velocity:float = 5;
@export var drag_velocity_multiplier:float = 0.4;
@export var suck_towards_finger_velocity:float = 6;
@onready var squish_feedback: Feedback_Squish = $SquishFeedback

var last_pos:Vector3;

var dragging:PlayerToken;
var drag_velocity:Vector3;

func _physics_process(delta: float) -> void:
	if stopped:
		return;
	if dragging != null:
		var distance:Vector3 = Vector3.ZERO;
		var now_pos:Vector3 = dragging.global_position;
		distance = Plane.PLANE_XZ.project(now_pos - last_pos);
		last_pos = now_pos;
		var new_drag_velocity:Vector3 = distance / delta;
		drag_velocity = drag_velocity.lerp(new_drag_velocity, 0.5);
		var actual_distance:Vector3 = (dragging.global_position - get_pos());
		var suck_velocity:Vector3 = actual_distance * suck_towards_finger_velocity;
		walk(distance + suck_velocity * delta);
		#walk(distance);
	else:
		walk(drag_velocity * drag_velocity_multiplier * delta);
		drag_velocity = drag_velocity.move_toward(Vector3.ZERO, decay_velocity * delta);
	

const max_iterations:int = 3;

func test_and_get_distance(distance:Vector3)->Vector3:
	var kin := body.move_and_collide(distance, true, 0.0001, false, 3);
	if kin:
		var travel:Vector3 = kin.get_travel();
		if travel.y != 0:
			travel = Vector3.ZERO;
		var rest:Vector3 = kin.get_remainder();
		for index:int in range(kin.get_collision_count()):
			var dot:float =  kin.get_normal(index).dot(rest.normalized());
			rest = rest.slide(-kin.get_normal(index));
		#print("[DRAG] [dist: %s] %s + %s = %s" % [
			#distance, travel, rest, travel + rest,
			#]);
		return travel + rest;
	else:
		#print("[DRAG] %s" % [distance]);
		return distance;
	
func get_pos()->Vector3:
	return body.global_position;	
	
func move_stuff(distance:Vector3):
	shape_cast_3d.target_position = distance;
	shape_cast_3d.force_shapecast_update();
	if shape_cast_3d.is_colliding():
		print_rich("[color=white]shape cast hit! Denied![/color]")
		return;
	
	body.global_position += distance;
	walk_together.global_position += distance;

var last_y:float;
func walk(distance:Vector3):
	distance.y = 0;
	distance = distance.limit_length(1.0);
	if distance.length_squared() > 0.0:
		move_stuff(test_and_get_distance(distance));
		
		#if body.global_position.y != last_y:
			#print_rich("[color=red]Moved y to %s!![/color]" % body.global_position.y);
			#last_y = body.global_position.y;

func _start_pressing(p:Player.TouchData):
	squish_feedback.squish();
	last_pos = p.instance.global_position;
	dragging = p.instance;
	#print("[DRAGGABLE] drag added" % [last_pos]);

func _end_pressing(p:Player.TouchData):
	squish_feedback.unsquish();
	dragging = null;
	#print("[DRAGGABLE] drag removed" % [last_pos]);
