class_name VFX_PillarOfLight extends Poolable

@export var anim: AnimationPlayer


func _enter_tree() -> void:
	anim.play(&"appearing")
	await anim.animation_finished
	anim.play(&"on")
	await get_tree().create_timer(15).timeout
	ObjectPool.repool(self);
