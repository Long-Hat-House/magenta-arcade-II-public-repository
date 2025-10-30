class_name DamageArea extends Area3D

@export var amountDamage:float = 0.1;
@export var enabled:bool = true;
@export var negate_body:Array[Node3D];
@export var scores:bool = true;
@export var dont_let_delay:bool;
@export var damage_on_contact:bool = true;
@export var damage_beat_duration:float = 0;
@export var recover_mana:bool = false;

@export_category("Damage Bonus")
@export var bonus_resource:UpgradeInfo;
@export var damage_per_progress:float;

@export_category("Debug")
@export var debug:bool = false;

signal damage_pulse;
signal onDamaged;
signal onDamagedData(data:Health.DamageData, victim:Node3D);

var count:float;
var bodies_inside:Array[Node3D] = [];

func _ready()-> void:
	self.body_entered.connect(_on_body_entered);
	self.body_exited.connect(_on_body_left);
	self.area_entered.connect(_on_area_entered);
	self.area_exited.connect(_on_area_left);
	
	
func hits_over_time()->bool:
	return damage_beat_duration > 0;	
	
	
func _on_body_entered(body:Node3D):
	if damage_on_contact:
		damage(body);
	bodies_inside.push_back(body);
		
		
func _on_body_left(body:Node3D):
	bodies_inside.erase(body);
		
		
func _on_area_entered(area:Area3D):
	_on_body_entered(area);
	
	
func _on_area_left(area:Area3D):
	_on_body_left(area);	
	
func enable_and_damage():
	enabled = true;
	damage_all_bodies();
	
func damage(body:Node3D)->bool:
	if enabled: 
		if negate_body.has(body):
			if debug:
				print("[DAMAGE DEBUG] Trying to damage %s but negated" % [body]);
			return false;
		var dd:Health.DamageData = Health.DamageData.new(amountDamage, self, scores, recover_mana)
		dd.never_delayed = dont_let_delay;
		if debug:
			print("[DAMAGE DEBUG] Trying to damage %s with %s [%s]" % [body, dd, Engine.get_physics_frames()]);
			print_stack();
		if Health.Damage(body, dd):
			onDamaged.emit();
			onDamagedData.emit(dd, body);
			count = damage_beat_duration;
			return true;
	return false;
	
func damage_all_bodies():
	for body in bodies_inside:
		damage(body);
	
func _physics_process(delta: float) -> void:
	if hits_over_time():
		count -= delta;
		while count <= 0:
			count += damage_beat_duration;
			damage_pulse.emit();
			damage_all_bodies();
