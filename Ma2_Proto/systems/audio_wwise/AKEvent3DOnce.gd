class_name AKEvent3DOncePerFrame extends Node3D

@export var akEvent:AkEvent3D;
@export var trigger_when:AkUtils.GameEvent;
@export var stop_when:AkUtils.GameEvent;


static var current_events:Array[WwiseEvent];

func _ready() -> void:
	match trigger_when:
		AkUtils.GAMEEVENT_ENTER_TREE:
			tree_entered.connect(post_event);
			post_event();
		AkUtils.GAMEEVENT_READY:
			ready.connect(post_event);
			post_event();
		AkUtils.GAMEEVENT_EXIT_TREE:
			tree_exited.connect(post_event);
		
	
	match stop_when:
		AkUtils.GAMEEVENT_ENTER_TREE:
			tree_entered.connect(stop_event);
			stop_event();
		AkUtils.GAMEEVENT_READY:
			ready.connect(stop_event);
			stop_event();
		AkUtils.GAMEEVENT_EXIT_TREE:
			tree_exited.connect(stop_event);
			

func post_event():
	if current_events.has(akEvent.event):
		return;
	current_events.append(akEvent.event);
	_call_event_instant.call_deferred();
	
func _call_event_instant():
	akEvent.post_event();
	current_events.erase(akEvent.event);
	
func stop_event():
	akEvent.stop_event();
