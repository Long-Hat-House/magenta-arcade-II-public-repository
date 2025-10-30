class_name DamageNode extends Node

@export var origin:Node3D;
@export var amountDamage:float = 1;
@export var enabled:bool = true;
@export var negate_body:Array[Node3D];
@export var scores:bool = true;
@export var damage_beat_duration:float = 0;
@export var recover_mana:bool = false;
@export var only_valid_after_seconds:float = 0.5;

@export var _debug:bool;
@export var _debug_every_collider_sibling:bool;

signal onDamaged;
signal onDamagedData(data:Health.DamageData, victim:Node3D);

var count:float;
var bodies_inside:Array[Node3D];

var entered_tree_mark:int;

func _enter_tree() -> void:
	entered_tree_mark = Time.get_ticks_msec();
	
func _ready()-> void:
	entered_tree_mark = Time.get_ticks_msec();
	if hits_over_time():
		bodies_inside = [];
	
func time_since_entered_tree()->float:
	return float(Time.get_ticks_msec() - entered_tree_mark) * 0.001;
	
func hits_over_time()->bool:
	return damage_beat_duration > 0;	
	
func add_area(area:Area3D):
	add_body(area);
	
func remove_area(area:Area3D):
	remove_body(area);	
	
func add_body(body:Node3D):
	if _debug:
		print("[Damage Node] Touched %s!" % body)
	if time_since_entered_tree() > only_valid_after_seconds:
		damage(body);
		if bodies_inside:
			if _debug:
				print("[Damage Node] Added body %s!" % body)
			bodies_inside.push_back(body);
		
func remove_body(body:Node3D):
	if bodies_inside:
		if _debug:
			print("[Damage Node] Removed body %s!" % body)
		bodies_inside.erase(body);
		
func damage(body:Node3D)->bool:
	if negate_body.has(body):
		return false;
	
	if enabled: 
		var dd:Health.DamageData = Health.DamageData.new(amountDamage, origin, scores, recover_mana)
		if Health.Damage(body, dd):
			onDamaged.emit();
			onDamagedData.emit(dd, body);
			count = damage_beat_duration;
			if _debug:
				print("[Damage Node] Damaged %s!" % body)
				if _debug_every_collider_sibling:
					for node:Node in get_parent().get_children():
						if node is CollisionShape3D:
							print("[Damage Node]\tCollider %s on %s while target is %s" % [node, (node as Node3D).global_position, body.global_position]);
			return true;
	return false;
	
func _damage_bodies_inside():
	for body in bodies_inside:
		damage(body);
		
	
func _physics_process(delta: float) -> void:
	if hits_over_time():
		while count <= 0:
			count += damage_beat_duration;
			_damage_bodies_inside();
	count -= delta;
