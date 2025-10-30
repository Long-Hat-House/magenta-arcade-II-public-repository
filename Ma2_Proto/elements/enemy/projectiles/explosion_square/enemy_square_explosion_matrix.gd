extends Node3D

@export var explosion_part:PackedScene;
@export var explosion_size:float = 1;
@export var explosion_layers:int = 5;
@export var explosion_delay:float = 0.1;
@export var screen_shake:CameraShakeData;

@export_category("SFX")
@export var sfx_explosion:AkEvent3D
@export var sfx_explosion_start:AkEvent3D


func is_valid()->bool:
	return get_parent() != null;

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	if not self.NOTIFICATION_READY: await self.ready;
	await get_tree().process_frame;
	if not is_valid(): return;
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash);

	if screen_shake:
		screen_shake.screen_shake();

	var layer:int = 0;
	_instantiate(Vector3.ZERO);
	sfx_explosion_start.post_event()
	sfx_explosion.post_event();
	await get_tree().create_timer(explosion_delay, false).timeout;
	layer += 1;

	while layer < explosion_layers:
		for col in range(0, layer+1):
			if col == 0: #first column it's just up and down
				_instantiate(Vector3(0, 0, explosion_size*layer));
				_instantiate(Vector3(0, 0, -explosion_size*layer));
			else: #other columns it's up and down to the right + up and down to the left
				_instantiate(Vector3(explosion_size*col, 0, explosion_size*layer));
				_instantiate(Vector3(explosion_size*col, 0, -explosion_size*layer));
				_instantiate(Vector3(-explosion_size*col, 0, explosion_size*layer));
				_instantiate(Vector3(-explosion_size*col, 0, -explosion_size*layer));

			if col == layer: #last column we also fill the rows
				for row in range(0, layer):
					if row == 0: #first row it's just left and right
						_instantiate(Vector3(-explosion_size*layer, 0, 0));
						_instantiate(Vector3(explosion_size*layer, 0, 0));
					else: #other rows it's left and right up + left and right down
						_instantiate(Vector3(-explosion_size*layer, 0, explosion_size*row));
						_instantiate(Vector3(explosion_size*layer, 0, explosion_size*row));
						_instantiate(Vector3(-explosion_size*layer, 0, -explosion_size*row));
						_instantiate(Vector3(explosion_size*layer, 0, -explosion_size*row));

		layer += 1
		sfx_explosion.post_event();
		await get_tree().create_timer(explosion_delay, false).timeout;
		if not is_valid(): break;

	ObjectPool.repool(self);

var amount_instantiated:int = 0;
func _instantiate(offset:Vector3):
	amount_instantiated += 1;
	#print("[EXPLOSION MATRIX] %s instantiated %s" % [self, amount_instantiated]);
	InstantiateUtils.InstantiateInTree(explosion_part, self, offset);
