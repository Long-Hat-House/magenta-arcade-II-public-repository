extends Node3D


var count:float;
@export var active:bool = true;

@export var time_multiplier:float = 1;
@export var radius:float;

@export var circle_multiplier:Vector2 = Vector2.ONE;
@export var circle_normal:Vector3 = Vector3.BACK;

@onready var health: Health = $Area3D/Health

signal dead;


var pos_balance:Vector3;
@export var target:Node3D;

func _ready():
	if target == null:
		target = get_child(0);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if active:
		count += delta * time_multiplier;
		
		##Circle
		var pos:Vector3 = VectorUtils.get_circle_point(count, circle_normal, circle_multiplier);
		
		target.position = pos;
	
func restore():
	health.restore();
	
