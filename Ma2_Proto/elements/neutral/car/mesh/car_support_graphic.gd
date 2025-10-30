class_name Graphic_Car_Support extends LHH3D

@onready var suporte_01:MeshInstance3D = $teto_solar
@onready var suporte_02:MeshInstance3D = $antena
@onready var suporte_03:MeshInstance3D = $rack
#@onready var suporte_04:MeshInstance3D = $escada

@onready var supports:Array[MeshInstance3D] = [suporte_01, suporte_02, suporte_03]#, suporte_04]
@export var chances_that_no_support_is_picked:int = 2;


func randomize_supports(seed:int):
	
	var randNumber:int = rand_from_seed(seed)[0];
	var calc:int = 1;
	for i:int in range(supports.size()):
		set_support((randNumber & calc) != 0, i)
		calc = calc << 1;
	#var sup:int = randNumber % (supports.size() + chances_that_no_support_is_picked); #make it less likely that any of them is selected
	#for i in range(supports.size()):
		##set_support(floor(randNumber / pow(10, a)) % 2 > 0, a);
		#set_support(i == sup, i);


func set_support(on:bool, which:int):
	if supports[which]:
		supports[which].visible = on;
