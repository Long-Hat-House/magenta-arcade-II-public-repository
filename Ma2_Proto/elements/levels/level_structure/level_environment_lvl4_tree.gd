class_name Level4_AnimationTree extends AnimationTree

@export var inside:bool;
@export var mid_boss:bool;
@export var final_boss:bool;
@export var boss_phase:int;

enum LastBossPhase {
	INTRO_BLACK = 0,
	LAB,
	CHASE,
	DESPERATION,
}
