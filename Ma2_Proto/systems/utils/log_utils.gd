class_name LogUtils

static func log_error(message:String, stack:bool = false):
	print_rich("[bgcolor=red][color=white]%s[/color][/bgcolor]" % message);
	push_error(message);
	if stack:
		print_stack();
		

static func log_warning(message:String, stack:bool = false):
	print_rich("[color=yellow]%s[/color]" % message);
	push_warning(message);
	if stack:
		print_stack();
