class_name Tokenizer

const LASER_TOKEN:String = "Laser";

class TokenState:
	var nodes:Array[Node] = [];
	signal free_token;

	func has_valid_nodes(amount:int)->bool:
		for node in nodes:
			if node and is_instance_valid(node):
				amount -= 1;
				if amount < 0:
					return true;
		return false;

static var tokens:Dictionary[String, TokenState];

static func await_next_token_and_pick(token:String, who:Node, no_more_than:int = 0):
	if tokens.has(token):
		while tokens[token].has_valid_nodes(no_more_than):
			await tokens[token].free_token;
			if !is_instance_valid(who):
				return;
	else:
		tokens[token] = TokenState.new();
	tokens[token].nodes.append(who);
	var free_token_callable:Callable = free_token.bind(token, who);
	if not who.tree_exited.is_connected(free_token_callable):
		who.tree_exited.connect(free_token_callable, CONNECT_ONE_SHOT);

static func free_token(token:String, who:Node):
	if tokens.has(token) and tokens[token].nodes.has(who):
		tokens[token].nodes.erase(who);
		tokens[token].free_token.emit();
		if tokens[token].nodes.size() <= 0:
			tokens.erase(token);

static func free_all_tokens():
	tokens.clear();
