extends StaticBody3D

@onready var _health:Health = $"Health";
@onready var graphic:Graphic_Car = $"Model";
@export var vfx_destroy:PackedScene;

var originalBasis:Basis;

var _timeTolerance:float = 0.03;
var _hitMark:float;

var damageDirection:Vector3;

signal pressed;
signal unpressed;

func _on_health_hit(damage:Health.DamageData , health:Health):
	graphic.hit(damage.origin);

func _on_health_dead(health:Health):
	var frames:int = 4;
	var tree = get_tree();
	while(frames > 0):
		frames -= 1;
		await tree.process_frame;
	if not self or not is_instance_valid(self):
		return;

	graphic.walk_health_phase();
	health.set_immunity_mark(0.5);
	health.restore();
	if vfx_destroy:
		InstantiateUtils.InstantiateInTree(vfx_destroy, graphic);
	if graphic.get_current_health_phase() == Graphic_Car.HealthPhase.Destroyed:
		queue_free();


func _on_pressable_pressed_player(touch:Player.TouchData):
	pressed.emit();
	graphic.set_possible_to_hit(false);
	graphic.relax();

func _on_pressable_released_player(touch:Player.TouchData):
	unpressed.emit();
	graphic.set_possible_to_hit(true);
	_health.kill();
