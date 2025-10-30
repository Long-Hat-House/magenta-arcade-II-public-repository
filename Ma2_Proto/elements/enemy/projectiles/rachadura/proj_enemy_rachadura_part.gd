extends Node3D

@onready var notifier: VisibleOnScreenNotifier3D = $Area/VisibleOnScreenNotifier3D

@onready var stones: Node3D = $Area/Stones

@export var mesh:MeshInstance3D;
var mesh_height:float;

@export var time_out:float = 1;
@export var time_there:float = 3.0 - 0.35;
@export var time_in:float = 0.35;
@onready var area: Area3D = $Area

@export var sound:WwiseEvent;

var count_physics:float;
var count:float;

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	queue_free();

func _ready() -> void:
	area.monitoring = false;
	area.monitorable = false;
	
	mesh_height = mesh.position.z;
	
	sound.post(area);

func _physics_process(delta: float) -> void:
	count_physics += delta;
	
	if count_physics > time_in:
		area.monitoring = false;
		area.monitorable = false;
	elif count_physics > 0.25 and not area.monitoring:
		area.monitoring = true;
		area.monitorable = true;
	
	if count_physics > time_in + time_out + time_there:
		queue_free.call_deferred();
		
func _process(delta: float) -> void:
	count += delta;
	var progress_stones:float = clamp(inverse_lerp(0, time_in, count), 0.0, 1.0)
	stones.set_progress(smoothstep(0.0, 1.0, progress_stones));
	
	var progress_position:float = clampf(inverse_lerp(time_in + time_there, time_in + time_there + time_out, count), 0.0, 1.0);
	stones.position.z = lerpf(0.75, 0.0, 1.0 - progress_position);
	mesh.position.z = lerpf(mesh_height, 0.15, smoothstep(0.0, 1.0, progress_stones - progress_position));
