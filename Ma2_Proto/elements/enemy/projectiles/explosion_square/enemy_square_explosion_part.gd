extends Node3D
@onready var graphic:Graphic_Explosion_Grande = $Graphic/explosionGrande_graphic as Graphic_Explosion_Grande;
@onready var square_explosion_part:Area3D = $"Square Explosion Part"
@export var collider_functioning_time:float = 0.15;

var readied:bool;

func is_valid():
	return self.get_parent() != null;

func _ready():
	readied = true;

func _enter_tree():
	if not readied: await self.ready;
	square_explosion_part.enabled = true;
	deactivate_collision(0.05);
	await graphic.play();
	if not is_valid(): return;
	ObjectPool.repool(self);

func deactivate_collision(delay:float):
	await get_tree().create_timer(delay).timeout;
	square_explosion_part.enabled = false;
