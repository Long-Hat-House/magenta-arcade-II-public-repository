class_name GenericTumbler extends Node3D

@export var disabled:bool;

@export_category("Tumbling")
@export var receiver:ForceReceiver;
@export var to_tumble:Node3D = self;
@export var tumble_data:ForceTumbleData;
@export var tumble_radius:float = 0.5;
@export var tumble_box_corner:Node3D;
@export var up_from_circle_relative:Vector3 = Vector3.UP;
@export var up_from_circle_getter:Node3D;
@export var random_force:float = 0;
@export var only_in_screen:VisibleOnScreenNotifier3D;

var moment:ForceTumbleData.Moment;

var up_from_circle:Vector3;
var rot:Quaternion;

@export_category("Trembling")
@export var health:Health;
@export var tremble_direction:Vector3 = (Vector3.ONE - Vector3.UP) * 0.05;
var tremble_count:float;
@export var tremble_duration:float = 0.5;


var current_health:Health;
var origin_position:Vector3;

var last_force:Vector3;

var _old_force:Vector3;

func _ready() -> void:
	moment = ForceTumbleData.Moment.new(random_force);
	
	if up_from_circle_getter:
		up_from_circle = up_from_circle_getter.global_basis.y.normalized();
	else:
		up_from_circle = Quaternion(Vector3.UP, to_tumble.get_parent_node_3d().global_basis.y.normalized()) * up_from_circle_relative;
	rot = Quaternion(Vector3.UP, up_from_circle).normalized();
	origin_position = to_tumble.position;

func _enter_tree() -> void:
	if receiver:
		receiver.force_received.connect(_received_force);
	if health:
		assign_health(health);

func _exit_tree() -> void:
	if receiver:
		receiver.force_received.disconnect(_received_force);
	if health:
		deassign_health(health);

func assign_health(h:Health):
	if current_health != null:
		deassign_health(current_health);
	h.hit.connect(_on_hit);
	current_health = h;

func deassign_health(h:Health):
	if h.hit.is_connected(_on_hit):
		h.hit.disconnect(_on_hit)

func deactivate():
	disabled = true;
	to_tumble.basis = Basis.IDENTITY;
	to_tumble.position = origin_position;

func _process(delta:float)->void:
	if disabled or not to_tumble.is_visible_in_tree() or not GraphicSettingsManager.instance.get_wind_feedback_enabled():
		return;
	elif only_in_screen == null or only_in_screen.is_on_screen():
		var force:Vector3 = tumble_data.change_and_tumble_process(moment, last_force, to_tumble.global_transform.basis.get_scale(), delta);

		if not force.is_equal_approx(_old_force):
			if tumble_box_corner:
				TransformUtils.tumble_rect(to_tumble, rot * force, tumble_box_corner.position, up_from_circle);
				pass;
			else:
				TransformUtils.tumble_circle(to_tumble, rot * force, tumble_radius, up_from_circle)
				pass;
			_old_force = force;

		if tremble_count > 0:
			tremble_count -= delta;
			if tremble_count < 0: tremble_count = 0;

			var value:float = tremble_count / tremble_duration;
			TransformUtils.tremble(to_tumble, tremble_direction * value, origin_position);


func _received_force(force:Vector3, delta:float):
	last_force = force;

func _on_hit(damage:Health.DamageData, h:Health) -> void:
	tremble_count = tremble_duration;
	tumble_data.hit(damage, self, moment);
