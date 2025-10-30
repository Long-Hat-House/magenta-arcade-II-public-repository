class_name Graphic_Statue_Ivo extends LHH3D

@onready var estatua_ivo_base:MeshInstance3D = $estatua_ivo_base
@onready var estatua_ivo_corpo:MeshInstance3D = $estatua_ivo_base/estatua_ivo_corpo
@onready var estatua_ivo_cabeca:MeshInstance3D = $estatua_ivo_base/estatua_ivo_corpo/estatua_ivo_cabeca
@onready var estatua_ivo_olho:MeshInstance3D = $estatua_ivo_base/estatua_ivo_corpo/estatua_ivo_cabeca/estatua_ivo_olho
@onready var instantiate_place:Node3D = $estatua_ivo_base/estatua_ivo_corpo/estatua_ivo_cabeca/estatua_ivo_olho/InstantiatePlace

@export var material_ok:BaseMaterial3D;
@export var material_destroyed:BaseMaterial3D;

@onready var position_head_a: Node3D = $estatua_ivo_base/estatua_ivo_corpo/PositionHead_A
@onready var position_head_b: Node3D = $estatua_ivo_base/estatua_ivo_corpo/PositionHead_B


@onready var all_parts:Array[MeshInstance3D] = [
	estatua_ivo_base,
	estatua_ivo_corpo,
	estatua_ivo_cabeca,
	estatua_ivo_olho
]

@onready var shake_parts:Array[MeshInstance3D] = [
	estatua_ivo_base,
	estatua_ivo_corpo
]

@onready var change_material_parts:Array[MeshInstance3D] = [
	estatua_ivo_base,
	estatua_ivo_corpo,
	estatua_ivo_cabeca,
]

@onready var wave_shake_parts:Array[MeshInstance3D] = [
	estatua_ivo_base,
	estatua_ivo_corpo,
	estatua_ivo_cabeca,
]

@onready var tilt_parts:Array[MeshInstance3D] = [
	estatua_ivo_base,
	estatua_ivo_corpo
]

@onready var partsToInitialPositions:Dictionary[MeshInstance3D, Vector3];


#var head_rotation_axis:Vector3 = (Vector3.UP + Vector3.FORWARD).normalized();
var head_rotation_axis:Vector3 = (Vector3.FORWARD).normalized();
var head_rotation:float:
	get:
		return head_rotation;
	set(value):
		head_rotation = value;
		var composite_basis:Basis = position_head_a.basis.slerp(position_head_b.basis, value);
		var origin:Vector3 = position_head_a.position * (1.0 - value) + position_head_b.position * value;
		estatua_ivo_cabeca.transform = Transform3D(composite_basis, origin);
		

func destroyed_face():
	var t:Tween = create_tween();
	t.tween_property(self, "head_rotation", 1, 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);
	t.play();
	await t.finished;
	
func apply_material(m:Material):
	for mesh in change_material_parts:
		mesh.set_surface_override_material(0, m);
	
func apply_ok_material():
	apply_material(material_ok);
	
func apply_destroyed_material():
	apply_material(material_destroyed);
	
func destroyed_face_immediate():
	head_rotation = 1;

func get_instantiate_place()->Node3D:
	return instantiate_place;
	
func _ready():
	for part in all_parts:
		partsToInitialPositions[part] = part.position;
	apply_ok_material();


func _process(delta:float):
	for statue in shake_parts:
		statue.position = partsToInitialPositions[statue]
	if _shakeValue != _shakeValueOld:
		for statue in shake_parts:
			statue.position += VectorUtils.rand_vector3_range(-0.5, 0.5) * _shakeValue;
		_shakeValueOld = _shakeValue;
	_wave_shake_add_process(delta, wave_shake_parts);
		
	if _tiltValue != _tiltValueOld:
		var tiltVector:Vector3;
		var tiltValue:float = _tiltValue;
		for statue_part in tilt_parts:
			tiltVector = Vector3.UP.slerp(_tiltDirection, tiltValue);
			tiltValue = move_toward(tiltValue, 0, tiltValue * 4 * delta);
			statue_part.basis = BasisUtils.rotate_from_up_to(tiltVector).orthonormalized();
		_tiltValueOld = _tiltValue;
	
var _shakeTween:Tween;
var _shakeValue:float;
var _shakeValueOld:float;

func shake(duration:float, shakeMaxDistance:float):
	if _shakeTween and _shakeTween.is_running(): _shakeTween.kill();
	_shakeTween = create_tween();
	_shakeValue = shakeMaxDistance;
	_shakeTween.tween_property(self, "_shakeValue", 0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART);
	
var _tiltTween:Tween;
var _tiltDirection:Vector3;
var _tiltValue:float;
var _tiltValueOld:float;

func tilt(where:Vector3, durationIn:float, durationOut:float):
	if _tiltTween and _tiltTween.is_running(): _tiltTween.kill();
	_tiltTween = create_tween();
	_tiltDirection = where;
	print("[GRAPHIC BOSS STATUE tilt direction change %s] [%s] " % [where, Engine.get_process_frames()]);
	_tiltValue = 0;
	_tiltTween.tween_property(self, "_tiltValue", 1, durationIn).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
	_tiltTween.tween_property(self, "_tiltValue", 0, durationOut).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);

@export var sneezers_big:Array[GPUParticles3D] = [];
@export var sneezers_small:Array[GPUParticles3D] = [];
@export var shake_default_curve:Curve;
var current_step:int = 0;
var shield_count:float;
var fail_count:float;
	
var eye_material:StandardMaterial3D;
func set_eyes(set_enabled:bool, force:float = 4):
	if eye_material == null:
		eye_material = (estatua_ivo_olho.get_surface_override_material(0) as StandardMaterial3D).duplicate();
		estatua_ivo_olho.set_surface_override_material(0, eye_material);
	eye_material.emission_enabled = set_enabled
	eye_material.emission_energy_multiplier = force
		
var wave_shake01:float;
var wave_shake_force:Vector3;

func sneeze_small():
	_sneeze(sneezers_small);

func sneeze_big():
	_sneeze(sneezers_big);
	
func _sneeze(a:Array[GPUParticles3D]):
	for sneezer in a:
		sneezer.restart();
		sneezer.emitting = true;
		
func set_wave_shake_default(wave01:float, shake_force:Vector3 = Vector3(1.5,0.0,0.75)):
	set_wave_shake(1, shake_default_curve.sample(wave01) * shake_force);
		
func set_wave_shake(wave01:float, shake_force:Vector3):
	wave_shake01 = wave01;
	wave_shake_force = shake_force;
	
func _wave_shake_add_process(delta:float, array:Array[MeshInstance3D]):
	if wave_shake_force.length_squared() > 0.001:
		var size:int = array.size();
		
		for index:int in range(size):
			var target:float = (float(index) / size) + (0.5 / size);
			
			var target_force:float = (1.0 - absf(wave_shake01 - target));
			target_force = remap(target_force, 0.5 / size, 1.0, 0.0, 1.0);
			
			array[index].position = partsToInitialPositions[array[index]] + 0.2 * target_force * VectorUtils.rand_vector3_range_vector(wave_shake_force);
		
