extends Node3D

@export var dialogue_id:String;
@export var extra_dialogue_id:Array[String];
@export var appearence_fixed:GraphicNPC_RegularRandomizer.Type;
@export var side:Side;
@export var stop_dialogue_on_death:bool = true;
@export var overwrite_delay:bool;
@export var new_delay:float;

enum Side{
	BELIEVER,
	MAGENTA,
}

@onready var quick_dialogue: QuickDialogue = $QuickDialogue
@onready var npc: Node3D = $"."
@onready var randomize_sprite_frames: GraphicNPC_RegularRandomizer = $Npc_Basic/NPC_Graphic_Regular/RandomizeSpriteFrames

signal conversation_started;
signal conversation_ended;


func _ready() -> void:
	quick_dialogue.flow_started.connect(conversation_started.emit);
	quick_dialogue.flow_stopped.connect(conversation_ended.emit);
	quick_dialogue.dialogue_id = get_dialogue_id();
	
	if overwrite_delay:
		quick_dialogue.delay = new_delay;
	
	if appearence_fixed != GraphicNPC_RegularRandomizer.Type.None:
		randomize_sprite_frames.make_type(appearence_fixed);


func get_dialogue_id()->String:
	var index:int = randi_range(0, 0 + extra_dialogue_id.size());
	if index == 0:
		return dialogue_id;
	else:
		return extra_dialogue_id[index - 1];

func _on_quick_dialogue_speech_start() -> void:
	npc.scale = Vector3(0.9,1.2,0.9);
	npc.create_tween().tween_property(npc, "scale", Vector3(1,1,1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);


func _on_health_dead(health: Health) -> void:
	if stop_dialogue_on_death and quick_dialogue and is_instance_valid(quick_dialogue):
		quick_dialogue.stop_dialogue();
