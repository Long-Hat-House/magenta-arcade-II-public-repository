class_name Graphic_Car_Armor extends LHH3D

@onready var lataria:MeshInstance3D = $lataria
@onready var farol:MeshInstance3D = $farol


var _mat:StandardMaterial3D;
var mat:StandardMaterial3D:
	get:
		if _mat == null:
			_mat = lataria.get_surface_override_material(0).duplicate();
			lataria.set_surface_override_material(0, _mat);
		return _mat;
		
static var light_mat_static:StandardMaterial3D;
static var light_mat_tween:Tween;
static var mat_count:int;

func make_farol_tween(mat:StandardMaterial3D)->Tween:
	var farol_tween = get_tree().create_tween();
	var default_color:Color = mat.emission;
	var default_intensity:float = mat.emission_intensity;
	mat.emission = Color.WHITE;
	mat.emission_energy_multiplier = 10;
	farol_tween.tween_property(mat, "emission", default_color, 0.7);
	farol_tween.tween_interval(0.6);
	#farol_tween.parallel().tween_property(mat, "emission_energy_multiplier", default_intensity, 0.9);
	farol_tween.tween_property(mat, "emission", Color.WHITE, 0.12);
	#farol_tween.parallel().tween_property(mat, "emission_energy_multiplier", 10, 0.12);
	farol_tween.set_loops();
	return farol_tween;

func _enter_tree() -> void:
	mat_count += 1;
	
func _ready() -> void:
	if light_mat_static == null:
		light_mat_static = farol.get_active_material(0).duplicate();
		light_mat_tween = make_farol_tween(light_mat_static);
	farol.material_override = light_mat_static;
	
func _exit_tree() -> void:
	mat_count -= 1;
	if mat_count <= 0:
		light_mat_tween.kill();
		light_mat_static = null;
		
var _light_mat:StandardMaterial3D;
var light_mat:StandardMaterial3D:
	get:
		if _light_mat == null:
			_light_mat = farol.get_active_material(0).duplicate();
			farol.material_override = _light_mat;
		return _light_mat;

var farol_tween:Tween;

func set_light(on:bool):
	farol.visible = on;

func get_color()->Color:
	return mat.albedo_color;

func set_color(albedo:Color, highlight:Color):
	mat.albedo_color = albedo;
	if mat.detail_albedo is GradientTexture1D:
		var g:GradientTexture1D =  mat.detail_albedo as GradientTexture1D;
		for p:int in range(g.gradient.get_point_count()):
			g.gradient.set_color(p, highlight);
