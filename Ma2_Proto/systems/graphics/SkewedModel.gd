extends Node3D

@export var angle:float = 45;
@export var addUpVector:float = 1;
@export var calculateEveryFrame:bool = false;

var vectorY:Vector3;

func _ready():
	#vectorY = self.basis.z.rotated(self.basis.x, -PI * 0.75);
	vectorY = Vector3.UP * addUpVector + self.basis.z.rotated(self.basis.x, -PI * 0.5 - deg_to_rad(angle));
	self.basis.y = vectorY;
	

func _process(delta:float)->void:
	#vectorY = self.basis.z.rotated(self.basis.x, PI * -0.5 + PI * 0.25 * sin((Time.get_ticks_msec() as float) / 1000));
	if calculateEveryFrame:
		vectorY = self.basis.z.rotated(self.basis.x, -PI + deg_to_rad(angle));
		self.basis.y = vectorY;
