extends MeshInstance3D

@export var path: Path3D
@export var laser_width: float = 1.8
@export var layer_width:float = 0.2;
@export var height_layer:float = 0.05;
@export var base_height:float = -0.2;
@export var pump_width_variance = 0.2;
@export var segments: int = 20

@export var material_border:Material;
@export var material_laser:Material;
@export var material_inner:Material;

var width_now_laser:float;
var width_now_layer:float;
var width_add:float;

var immediate_mesh:ImmediateMesh;

@export var inner_only:bool;

func _ready():
	immediate_mesh = self.mesh as ImmediateMesh;
	
	var t := create_tween();
	
	width_now_laser = 0;
	width_now_layer = 0;
	## Pump the width along time
	t.tween_property(self, "width_add", pump_width_variance * 0.5, 0.1).set_ease(Tween.EASE_OUT);
	t.tween_property(self, "width_add", -pump_width_variance * 0.5, 0.1).set_ease(Tween.EASE_OUT);
	t.set_loops(-1);
	
	
func make_laser_width(multiplier:float, duration:float = 0.4):
	var width_tween := create_tween();
	width_tween.tween_property(self, "width_now_laser", laser_width * multiplier, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	
func make_laser_layer_width(multiplier:float, duration:float = 0.4):
	var width_tween := create_tween();
	width_tween.tween_property(self, "width_now_layer", layer_width * multiplier, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	

func _process(_delta):
	update_laser()

func update_laser():
	immediate_mesh.clear_surfaces()
	
	make_surface(width_now_laser - width_now_layer * 0.0, base_height + height_layer * 0)
	make_surface(width_now_laser - width_now_layer * 1.0, base_height + height_layer * 1)
	make_surface(width_now_laser - width_now_layer * 2.0, base_height + height_layer * 2)
	immediate_mesh.surface_set_material(0, material_border)
	immediate_mesh.surface_set_material(1, material_laser)
	immediate_mesh.surface_set_material(2, material_inner)
	
func make_surface(width:float, height:float):
	if width < 0: return;
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var curve = path.curve
	for i in range(segments + 1):
		var t := i / float(segments)
		var pos := path.transform * curve.sample_baked_with_rotation(t * curve.get_baked_length())
		var normal := Vector3.UP  # Adjust based on your path orientation
		
		# Add vertices for the strip
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(pos.origin + pos.basis.x * width * 0.5 + pos.basis.y * height)
		immediate_mesh.surface_add_vertex(pos.origin - pos.basis.x * width * 0.5 + pos.basis.y * height)
	
	immediate_mesh.surface_end()
	
