class_name MenuAggregator extends Control

signal priority_changed()

@export var _subaggregator_scene:PackedScene

@export var _container_subaggregators:Control
@export var _container_elements:Control

@export var _label_title:Label
@export var _label_subtitle:Label

@export var _icon_rect:TextureRect

var title:String:
	set(val):
		title = val
		if _label_title:
			if title.is_empty():
				_label_title.hide()
			else:
				_label_title.show()
				_label_title.text = title

var subtitle:String:
	set(val):
		subtitle = val
		if _label_subtitle:
			if subtitle.is_empty():
				_label_subtitle.hide()
			else:
				_label_subtitle.show()
				_label_subtitle.text = subtitle

var priority:int = 0:
	set(val):
		priority = val
		priority_changed.emit()

var icon:Texture2D:
	set(val):
		icon = val
		if _icon_rect:
			_icon_rect.texture = icon

var _aggregators:Dictionary

var _element_priorities:Dictionary

func set_info(title:String, subtitle:String, priority:int = 0, icon:Texture2D = null):
	self.title = title
	self.subtitle = subtitle
	self.icon = icon

	self.priority = priority

func add_element(control:Control, priority:int = 0) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in control.get_children():
		if child is Control:
			var c = child as Control
			c.mouse_filter = Control.MOUSE_FILTER_PASS
	_container_elements.add_child(control)
	_element_priorities[control] = priority
	_reorder_elements_container()

func get_aggregator(path:Array[String]) -> MenuAggregator:
	if path.is_empty(): return self

	var ag:MenuAggregator = null
	var id = path.pop_front()
	if _aggregators.has(id) && is_instance_valid(_aggregators[id]):
		ag = _aggregators[id]
	else:
		ag = _subaggregator_scene.instantiate() as MenuAggregator
		ag.priority_changed.connect(_reorder_aggregators_container)
		ag.name = id
		_container_subaggregators.add_child(ag)
		_aggregators[id] = ag
		_reorder_aggregators_container()

	if path.is_empty(): return ag
	else: return ag.get_aggregator(path)

## Carefull! You might be breaking a lot of references here. Gotta know what u doing
func delete_all_elements_and_subs():
	for child in _container_elements.get_children():
		child.queue_free()
	for child in _container_subaggregators.get_children():
		child.queue_free()
	_aggregators.clear()
	_element_priorities.clear()

func _reorder_aggregators_container():
	_reorder_children(_container_subaggregators)

func _reorder_elements_container():
	_reorder_children(_container_elements)

func _reorder_children(container:Node):
	var sorted_nodes := container.get_children()

	sorted_nodes.sort_custom(
		# For descending order use > 0
		func(a: Node, b: Node):
			var get_node_priority:Callable = func(node:Node) -> int:
				var p = 1000

				if node is MenuAggregator:
					p = (node as MenuAggregator).priority
				if _element_priorities.has(node):
					p = _element_priorities[node]

				return p

			var a_val = get_node_priority.call(a)
			var b_val = get_node_priority.call(b)

			return a_val > b_val
	)

	var index = 0
	for node in container.get_children():
		container.remove_child(node)

	for node in sorted_nodes:
		container.add_child(node)


## Cria um botão interativo que abre um prompt de seleção de opções
##
## [b]Funcionalidades:[/b]
## - Exibe a opção selecionada como texto do botão
## - Suporta persistência de dados com [code]save[/code]/[code]save_id[/code]
## - Cria layout automático com label frontal quando necessário
##
## [b]Parâmetros:[/b]
## - [code]prompt_options[/code]  [Array[String]]: Opções disponíveis no prompt
## - [code]prompt_title[/code]    [String]: Título da janela de prompt
## - [code]prompt_text[/code]     [String] (opcional): Texto descritivo do prompt
## - [code]front_label[/code]     [String] (opcional): Label exibido antes do botão
## - [code]button_label[/code]    [String] (opcional): Texto fixo do botão
## - [code]save[/code]            [GameSave] (opcional): Sistema de persistência
## - [code]save_id[/code]         [StringName] (opcional): ID único para armazenamento
## - [code]selected_index_callback[/code] [Callable] (opcional): Callback de seleção (recebe [int])
## - [code]icon[/code]            [Texture2D] (opcional): Ícone do botão
##
## [b]Retorna:[/b]
## - [Control] Contendo ([HBoxContainer] + Label) ou [Button] puro
func create_prompt_button(
	prompt_options: Array[String],
	prompt_title: String,
	prompt_text: String = "",
	front_label: String = "",
	button_label: String = "",
	save: GameSave = null,
	save_id: StringName = "",
	selected_index_callback: Callable = Callable(),
	icon: Texture2D = null
) -> Control:
	var use_save: bool = save != null and not save_id.is_empty()
	var selected_index: int = (
		int(save.get_json_parsed_data(save_id, str(0)))
		if use_save
		else 0
	)

	var option_button: Button = Button.new()
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.text = button_label if not button_label.is_empty() else prompt_options[selected_index]
	if icon != null:
		option_button.icon = icon

	option_button.pressed.connect(
		func():
			var current_index: int = (
				int(save.get_json_parsed_data(save_id, str(0)))
				if use_save
				else 0
			)
			var prompt_entries: Array[PromptWindow.PromptEntry] = []

			# Add option buttons
			for id: int in prompt_options.size():
				var is_selected: bool = (id == current_index) if use_save else false
				prompt_entries.append(PromptWindow.PromptEntry.CreateButton(
					prompt_options[id],
					id,
					false,
					true,
					is_selected
				))

			PromptWindow.new_prompt_advanced(
				prompt_title,
				prompt_text,
				func(id: int):
					if id < 0 or id >= prompt_options.size():  # Close button clicked
						if selected_index_callback:
							selected_index_callback.call(id)
					else:  # Option selected
						if use_save:
							save.set_data(save_id, str(id))
						option_button.text = prompt_options[id]
						if selected_index_callback:
							selected_index_callback.call(id)
					,
				prompt_entries
			)
	)

	if selected_index_callback:
		selected_index_callback.call(selected_index)

	if not front_label.is_empty():
		var hbox: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = front_label
		hbox.add_child(label)
		hbox.add_child(option_button)
		add_element(hbox, 0)
		return hbox

	add_element(option_button)
	return option_button

## Cria um [CheckBox] configurável com persistência opcional
##
## [b]Parâmetros:[/b]
## - [code]button_label[/code]  [String]: Texto exibido ao lado do checkbox
## - [code]default_val[/code]  [bool] (padrão: false): Estado inicial quando não houver save
## - [code]toggled_callback[/code]  [Callable] (opcional): Função chamada ao alterar estado (recebe [bool])
## - [code]save[/code]  [GameSave] (opcional): Instância de salvamento para persistência
## - [code]save_id[/code]  [StringName] (opcional): ID único para armazenamento
##
## [b]Retorna:[/b] Referência ao [CheckBox] criado
func create_toggle_option(
	button_label: String,
	default_val: bool = false,
	toggled_callback: Callable = Callable(),
	save: GameSave = null,
	save_id: StringName = ""
) -> CheckBox:
	var use_save: bool = save != null and not save_id.is_empty()
	var selected_value: bool = (
		bool(save.get_data(save_id, "TRUE" if default_val else "FALSE") == "TRUE")
		if use_save
		else default_val
	)

	var toggle_button: CheckBox = CheckBox.new()
	toggle_button.text = button_label

	toggle_button.toggled.connect(
		func(tog_val: bool):
			if toggled_callback != Callable():
				toggled_callback.call(tog_val, false)
			if use_save:
				save.set_data(save_id, "TRUE" if tog_val else "FALSE")
	)

	toggle_button.set_pressed_no_signal(selected_value)
	if toggled_callback != Callable():
		toggled_callback.call(selected_value, true)
	add_element(toggle_button, 0)
	return toggle_button
