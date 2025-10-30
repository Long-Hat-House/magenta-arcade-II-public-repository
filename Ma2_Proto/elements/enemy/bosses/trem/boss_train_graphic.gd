class_name Boss_Trem_Graphic extends Node3D

@onready var face_center: Boss_Trem_Face = $faceTrain
@onready var face_right: Boss_Trem_Face = $faceTrain2
@onready var face_left: Boss_Trem_Face = $faceTrain3

@onready var animation: AnimationPlayer = $AnimationPlayer

@onready var canhao: MeshInstance3D = $canhao
@onready var light_01: MeshInstance3D = $canhao/light01
@onready var light_02: MeshInstance3D = $canhao/light02
@onready var light_03: MeshInstance3D = $canhao/light03
@onready var light_04: MeshInstance3D = $canhao/light04
@onready var lights:Array[MeshInstance3D] = [
	light_01,
	light_02,
	light_03,
	light_04,
]
@onready var energy_particles: GPUParticles3D = $canhao/EnergyParticles
@onready var light_ball: MeshInstance3D = $canhao/LightBall

@onready var vfx_smoke_pillar_r: VFX_Smoke_Pillar = $trem/VfxSmokePillarR
@onready var vfx_smoke_pillar_r_2: VFX_Smoke_Pillar = $trem/VfxSmokePillarR2
@onready var vfx_smoke_pillar_r_3: VFX_Smoke_Pillar = $trem/VfxSmokePillarR3
@onready var vfx_smoke_pillar_r_4: VFX_Smoke_Pillar = $trem/VfxSmokePillarR4
@onready var vfx_smoke_pillar_l: VFX_Smoke_Pillar = $trem/VfxSmokePillarL
@onready var vfx_smoke_pillar_l_2: VFX_Smoke_Pillar = $trem/VfxSmokePillarL2
@onready var vfx_smoke_pillar_l_3: VFX_Smoke_Pillar = $trem/VfxSmokePillarL3
@onready var vfx_smoke_pillar_l_4: VFX_Smoke_Pillar = $trem/VfxSmokePillarL4
@onready var smokes_r:Array[VFX_Smoke_Pillar] = [
	vfx_smoke_pillar_r,
	vfx_smoke_pillar_r_2,
	vfx_smoke_pillar_r_3,
	vfx_smoke_pillar_r_4,
]
@onready var smokes_l:Array[VFX_Smoke_Pillar] = [
	vfx_smoke_pillar_l,
	vfx_smoke_pillar_l_2,
	vfx_smoke_pillar_l_3,
	vfx_smoke_pillar_l_4,
]

func cannon_strike(duration:float, delay_secondary:float):
	set_cannon_progress(1);
	var t := create_tween();
	t.set_parallel();
	t.tween_property(light_ball, "scale", Vector3(20, 20, 2), duration).set_delay(delay_secondary).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	t.tween_property(light_ball, "position", Vector3(0, 0, 5), duration + delay_secondary).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	t.tween_property(light_ball.mesh.surface_get_material(0), "emission_energy_multiplier", 20.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	t.tween_property(light_ball.mesh.surface_get_material(0), "emission", Color.WHITE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);


func set_cannon_progress(ratio01:float):
	var ratio_better:float = ease(clampf(ratio01, 0.0, 1.0), 3.8);
	canhao.rotation.x = deg_to_rad(ratio_better * -60);
	energy_particles.amount_ratio = ratio_better;
	energy_particles.speed_scale = lerpf(1, 4, ratio01);
	light_ball.mesh.surface_get_material(0).set(&"emission_energy_multiplier", ratio_better);
	ArrayUtils.percentage_array_float_call_all(lights, ratio01, func(element:MeshInstance3D, ratio:float):
		element.visible = ratio > 0.75;
		)
		
var old_smoke_progress:float;
func set_smoke_progress(ratio01:float):
	ArrayUtils.percentage_array_float_call_one(range(smokes_r.size()), ratio01, old_smoke_progress, func(element:int, ratio:float):
		if ratio > 0.5:
			smokes_l[element].start();
			smokes_r[element].start();
		else:
			smokes_l[element].end();
			smokes_r[element].end();
		)
	old_smoke_progress = ratio01;
