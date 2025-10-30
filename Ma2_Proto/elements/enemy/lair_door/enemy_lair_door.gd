class_name Enemy_Lair_Door extends LHH3D

@onready var spawn_area: SpawnArea = $SpawnArea
@onready var health: Health = $StaticBody3D/Health
@onready var node_3d_shaker: Node3DShaker = $Node3DShaker

signal dead;
signal really_dead;

func _on_health_dead_parameterless() -> void:
	dead.emit();
	node_3d_shaker.shake_amplitude_ratio = 1;
	await spawn_area.do_spawn_default();
	really_dead.emit();
	HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
	queue_free();

func is_alive()->bool:
	return health.is_alive();
