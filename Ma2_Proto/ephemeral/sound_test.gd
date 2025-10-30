extends Node3D

@onready var event: AkEvent3D = $AkEvent3D
@onready var ak_bank: AkBank = $AkBank

func _ready() -> void:
	ak_bank.queue_free();
	ak_bank.load_bank();
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if event:
			event.post_event();
