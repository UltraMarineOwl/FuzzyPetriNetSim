# Scripts/Transition.gd
extends Node2D

class_name Transition

var index: int = -1
var element_name: String = ""

var input_weights: Dictionary = {}
var output_weights: Dictionary = {}

# Пример: input_weights[2] = 1.0 означает, что для места с index=2 нужен вес 1.0
#         output_weights[5] = 0.5 означает, что место с index=5 получит 0.5

var input_places: Array[Place] = []
var output_places: Array[Place] = []
var firing_threshold = 0.5  # Порог срабатывания перехода

var is_dragging: bool = false
var drag_offset: Vector2
var main
var is_connected: bool = false

func _ready():
	update_label()
	_update_name_label()
	if main == null:
		var possible_main = get_parent()
		while possible_main != null and not possible_main.has_method("_refresh_matrices_display"):
			possible_main = possible_main.get_parent()
		main = possible_main
	_update_matrix_label()

func set_element_name(new_name: String) -> void:
	element_name = new_name
	_update_name_label()

func _update_name_label() -> void:
	var label_node = $NameLabel
	if label_node != null:
		label_node.text = element_name

func update_label():
	$Label.text = "%.2f" % firing_threshold

func add_input_place(place_index: int, weight: float = 1.0) -> void:
	input_weights[place_index] = weight

func add_output_place(place_index: int, weight: float = 1.0) -> void:
	output_weights[place_index] = weight

func try_fire():
	var min_token_value = 1.0
	for place in input_places:
		min_token_value = min(min_token_value, place.token_value)
		
	if min_token_value >= firing_threshold:
		fire_transition(min_token_value)
		return true
	else:
		return false

func fire_transition(token_amount: float) -> void:
	# Обновляем значения меток
	for place in input_places:
		place.token_value = max(0.0, place.token_value - token_amount)
		place.update_label()
	for place in output_places:
		place.token_value = min(1.0, place.token_value + token_amount)
		place.update_label()
	print("Transition fired with token amount: ", token_amount)

func _input(event: InputEvent) -> void:
	if main != null and main.is_connect_mode_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			if _is_mouse_over(mouse_pos):
				_change_firing_threshold()
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			if event.pressed and _is_mouse_over(mouse_pos):
				is_dragging = true
				drag_offset = position - mouse_pos
			elif not event.pressed:
				is_dragging = false
	#elif event is InputEventMouseMotion and is_dragging:
		#position = get_global_mouse_position() + drag_offset
		#_update_connections()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click and event.pressed:
			is_dragging = false
			var mouse_global_pos = get_global_mouse_position()
			var query = PhysicsPointQueryParameters2D.new()
			query.position = mouse_global_pos
			query.collide_with_bodies = true   # Если ваш StaticBody2D - это тело
			query.collide_with_areas = false   # Устанавливайте true, если ищете и Area2D
			query.collision_mask = 0x7FFFFFFF  # Все слои, либо задайте нужную маску
			
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_point(query)

			# Результат - массив словарей, у каждого словаря есть поле collider
			for r in result:
				if r.collider == self or r.collider == $StaticBody2D:
					# Это значит, клик попал по нашему StaticBody2D
					# Вызываем логику двойного клика
					event.double_click
					_prompt_pre_post_dialog()
					break
	elif event is InputEventMouseMotion and is_dragging:
		position = get_global_mouse_position() + drag_offset
		_update_connections()
	if event is InputEventMouseMotion and is_dragging:
		position = get_global_mouse_position() + drag_offset
		# После изменения позиции, перерисовать линии
		var par = get_parent()
		if par != null and par.has_method("_update_connections"):
			par._update_connections()

func _change_firing_threshold() -> void:
	firing_threshold = max(0.0, firing_threshold - 0.1)
	update_label()

func _is_mouse_over(global_position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_bodies = true  # Если ваш узел использует StaticBody2D
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF
	query.exclude = []
	var results = space_state.intersect_point(query)
	for result in results:
		if result.collider == $StaticBody2D:
			return true
	return false
	
func _update_connections() -> void:
	# Уведомляем родителя о перемещении для обновления линий
	if get_parent().has_method("update_connections"):
		get_parent().update_connections()


func set_connected(connected: bool) -> void:
	is_connected = connected
	var sprite_node = $StaticBody2D/Sprite  # Убедитесь, что узел 'Sprite' существует в 'Place.tscn'
	if sprite_node == null:
		print("Sprite node not found in Place!")
		return
	if is_connected:
		sprite_node.modulate = Color(1, 1, 0)  # Желтый цвет при выборе
	else:
		sprite_node.modulate = Color(1, 1, 1)  # Обычный цвет

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.doubleclick:
			# Открыть интерфейс для изменения firing_threshold
			pass  # Реализуйте по необходимости

func _prompt_pre_post_dialog() -> void:
	if main == null:
		return # или иной способ получить ссылку на main
	if main == null:
		print("No Main found, cannot list places.")
		return
	
	var places_array = main.places
	if places_array.size() == 0:
		print("No places to edit.")
		return

	# Создаём окно
	var dialog = Window.new()
	dialog.title = "Edit Pre/Post for " + element_name
	dialog.size = Vector2(450, 400)
	dialog.position = get_viewport().get_visible_rect().size * 0.5 - dialog.size * 0.5

	# VBoxContainer, чтобы вертикально располагать элементы
	var main_vbox = VBoxContainer.new()
	dialog.add_child(main_vbox)

	# Прокручиваемое содержимое, если мест много
	var scroll = VBoxContainer.new()
	main_vbox.add_child(scroll)
	
	var content_vbox = VBoxContainer.new()
	scroll.add_child(content_vbox)

	# Место для хранения link-редитов
	var input_lineedits = {}
	var output_lineedits = {}

	# Проходим по всем местам
	for place in places_array:
		var place_index = place.index

		# Создаём HBox: [Label (place_name), LineEdit(Pre), LineEdit(Post)]
		var hbox = HBoxContainer.new()
		
		var place_label = Label.new()
		place_label.text = place.element_name # типа "p1"
		place_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(place_label)

		# LineEdit для Pre
		var pre_val = 0.0
		if input_weights.has(place_index):
			pre_val = input_weights[place_index]
			
		var pre_edit = LineEdit.new()
		pre_edit.text = str(pre_val)
		pre_edit.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(pre_edit)
		input_lineedits[place_index] = pre_edit

		# LineEdit для Post
		var post_val = 0.0
		if output_weights.has(place_index):
			post_val = output_weights[place_index]
			
		var post_edit = LineEdit.new()
		post_edit.text = str(post_val)
		post_edit.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(post_edit)
		output_lineedits[place_index] = post_edit
		
		content_vbox.add_child(hbox)

	# Кнопка "OK"
	var ok_button = Button.new()
	ok_button.text = "OK"
	main_vbox.add_child(ok_button)
	# Подключаем сигнал
	ok_button.pressed.connect(Callable(self, "_on_pre_post_ok_pressed").bind(dialog, input_lineedits, output_lineedits))
	
	add_child(dialog)
	dialog.popup()

func _on_pre_post_ok_pressed(
	dialog: Window,
	input_lineedits: Dictionary, 
	output_lineedits: Dictionary
	) -> void:
		
	for place_index in input_lineedits.keys():
		var pre_str = input_lineedits[place_index].text
		if pre_str.is_valid_float():
			input_weights[place_index] = pre_str.to_float()
		else:
			input_weights[place_index] = 0.0
	
	for place_index in output_lineedits.keys():
		var post_str = output_lineedits[place_index].text
		if post_str.is_valid_float():
			output_weights[place_index] = post_str.to_float()
		else:
			output_weights[place_index] = 0.0
	
	dialog.queue_free()

	# Теперь обновляем текст MatrixLabel
	_update_matrix_label()

	# Если нужно, также обновить глобальную матрицу в Main
	if main != null:
		main._refresh_matrices_display()

func _update_matrix_label() -> void:
	var lbl = $MatrixLabel
	if lbl == null:
		return

	# Соберём текст. К примеру, "Pre: {place_index: weight}, Post: ..."
	var pre_nums = []
	for place_idx in input_weights.keys():
		var w = input_weights[place_idx]
		if w != 0.0:
			pre_nums.append(str(w))
	
	var post_nums = []
	for place_idx in output_weights.keys():
		var w = output_weights[place_idx]
		if w != 0.0:
			post_nums.append(str(w))
	
	var pre_str = "(" + array_join(pre_nums, ", ") + ")"
	var post_str = "(" + array_join(post_nums, ", ") + ")"
	
	var text_str = pre_str + "\n" + post_str

	lbl.text = text_str

func array_join(arr: Array, sep: String) -> String:
	var result := ""
	for i in range(arr.size()):
		result += str(arr[i])
		if i < arr.size() - 1:
			result += sep
	return result
