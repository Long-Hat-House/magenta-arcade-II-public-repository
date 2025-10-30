class_name TimeUtils


static func delay(time:float, node:Node):
	await node.get_tree().create_timer(time).timeout
