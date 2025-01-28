# Scripts/Main.gd
extends Node2D

var PlaceScene = preload("res://Scenes/Place.tscn")
var TransitionScene = preload("res://Scenes/Transitions.tscn")

@onready var connections_node: Node2D = $Connections
@onready var file_dialog_save: FileDialog = FileDialog.new()
@onready var file_dialog_load: FileDialog = FileDialog.new()

# Переменные для кнопок режимов
var place_mode_button: CheckButton
var transition_mode_button: CheckButton
var connect_mode_button: CheckButton
var delete_mode_button: CheckButton
var fire_button: Button  # Если необходимо
var show_matrix: Button
var save_button: Button
var load_button: Button
var mode_button_group: ButtonGroup = ButtonGroup.new()

var is_place_mode_enabled: bool = false
var is_transition_mode_enabled: bool = false
var is_connect_mode_enabled: bool = false
var is_delete_mode_enabled: bool = false

var selected_place: Place = null
var selected_transition: Transition = null
var selected_transition_to_fire: Transition = null
var selected_node = null

var connections = []  # Список словарей с информацией о соединениях

var places: Array[Place] = []
var transitions: Array[Transition] = []


func _ready() -> void:
	#########################################
# Добавляем кнопку для переключения режима добавления мест
	place_mode_button = CheckButton.new()
	place_mode_button.text = "Add Places"
	place_mode_button.toggle_mode = true  # Позволяет кнопке работать как переключатель
	place_mode_button.button_group = mode_button_group
	place_mode_button.position = Vector2(10, 10)
	add_child(place_mode_button)
	place_mode_button.toggled.connect(_on_place_mode_toggled)
	
	#########################################
	# Добавляем кнопку для переключения режима добавления переходов
	transition_mode_button = CheckButton.new()
	transition_mode_button.text = "Add Transitions"
	transition_mode_button.toggle_mode = true
	transition_mode_button.button_group = mode_button_group
	transition_mode_button.position = Vector2(10, 50)
	add_child(transition_mode_button)
	transition_mode_button.toggled.connect(_on_transition_mode_toggled)
	
	#########################################
# Добавляем кнопку для режима связывания
	connect_mode_button = CheckButton.new()
	connect_mode_button.text = "Connect Nodes"
	connect_mode_button.toggle_mode = true
	connect_mode_button.button_group = mode_button_group
	connect_mode_button.position = Vector2(10, 100)
	add_child(connect_mode_button)
	connect_mode_button.toggled.connect(_on_connect_mode_toggled)
	
		#########################################
# Добавляем кнопку для режима связывания
	delete_mode_button= CheckButton.new()
	delete_mode_button.text = "Delete Nodes"
	delete_mode_button.toggle_mode = true
	delete_mode_button.button_group = mode_button_group
	delete_mode_button.position = Vector2(10, 150)
	add_child(delete_mode_button)
	delete_mode_button.toggled.connect(_on_delete_button_toggled)
	
	# Добавляем кнопку для срабатывания перехода
	fire_button = Button.new()
	fire_button.text = "Fire Transition"
	fire_button.position = Vector2(10, 200)
	add_child(fire_button)
	fire_button.pressed.connect(_on_fire_button_pressed)
	
	show_matrix = Button.new()
	show_matrix.text = "Show Matrix"
	show_matrix.position = Vector2(10, 250)
	add_child(show_matrix)
	show_matrix.pressed.connect(_on_show_matrices_button_pressed)
	
		#Saving system
	# Создаем и настраиваем FileDialog для сохранения
	file_dialog_save.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog_save.filters = ["*.json ; JSON files"]
	file_dialog_save.access = FileDialog.ACCESS_USERDATA
	add_child(file_dialog_save)
	file_dialog_save.file_selected.connect(_on_file_save_selected)

	# Создаем и настраиваем FileDialog для загрузки
	file_dialog_load.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog_load.filters = ["*.json ; JSON files"]
	file_dialog_load.access = FileDialog.ACCESS_USERDATA
	add_child(file_dialog_load)
	file_dialog_load.file_selected.connect(_on_file_load_selected)
		
		
	 # 1) Кнопка для сохранения
	save_button = Button.new()
	save_button.text = "Save Network"
	save_button.position = Vector2(10, 300)
	add_child(save_button)
	# Подключаем сигнал "pressed"
	save_button.pressed.connect(_on_save_button_pressed)

	# 2) Кнопка для загрузки
	load_button = Button.new()
	load_button.text = "Load Network"
	load_button.position = Vector2(10, 350)
	add_child(load_button)
	load_button.pressed.connect(_on_load_button_pressed)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.DARK_GRAY
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color.DARK_GRAY
	
	#Стилизация кнопок
	place_mode_button.add_theme_stylebox_override("hover", hover_style)
	transition_mode_button.add_theme_stylebox_override("hover", hover_style)
	connect_mode_button.add_theme_stylebox_override("hover", hover_style)
	
	place_mode_button.add_theme_color_override("font_color", Color.WHITE)
	transition_mode_button.add_theme_color_override("font_color", Color.WHITE)
	connect_mode_button.add_theme_color_override("font_color", Color.WHITE)
	
func _on_place_mode_toggled(button_pressed: bool) -> void:
	is_place_mode_enabled = button_pressed
	if button_pressed:
		is_transition_mode_enabled = false
		is_connect_mode_enabled = false
		selected_place = null
		selected_transition = null

func _on_transition_mode_toggled(button_pressed: bool) -> void:
	is_transition_mode_enabled = button_pressed
	if button_pressed:
		is_place_mode_enabled = false
		is_connect_mode_enabled = false
		selected_place = null
		selected_transition = null

func _on_connect_mode_toggled(button_pressed: bool) -> void:
	is_connect_mode_enabled = button_pressed
	if button_pressed:
		is_place_mode_enabled = false
		is_transition_mode_enabled = false
		selected_place = null
		selected_transition = null

func _on_delete_button_toggled(button_pressed: bool) -> void:
	is_delete_mode_enabled = button_pressed
	if button_pressed:
		is_delete_mode_enabled = true
		is_place_mode_enabled = false
		is_transition_mode_enabled = false
		is_connect_mode_enabled = false

func _create_place_at_position(position: Vector2) -> Place:
	
	## 1) Ищем свободный слот
	#var free_slot = -1
	#for i in range(places.size()):
		#if places[i] == null:
			#free_slot = i
			#break
	#
	## 2) Создаем объект
	#var place = PlaceScene.instantiate()
	#
	#if free_slot == -1:
		## Не нашли null => добавляем в конец
		#place.index = places.size()
		#places.append(place)
	#else:
		## нашелся свободный слот => place.index = free_slot
		#place.index = free_slot
		#places[free_slot] = place  # заменяем null на новый объект
#
	## 3) Далее стандартные действия
	#place.position = position
	#place.element_name = "p" + str(place.index + 1)
	#add_child(place)
	## place.update_display() или что вам нужно
	#return place
	
	var place: Place = PlaceScene.instantiate()
	place.index = places.size()  # Индекс места = текущий размер массива
	place.position = position
	
	# Формируем название: p1, p2, p3 и т. д.
	# Например: "p" + str(place.index + 1)
	place.set_element_name("p" + str(place.index + 1))
	add_child(place)
	
	#place.token_value = 0.0  # Начальное значение метки
	places.append(place) #добавляю запись для места
	return place

func _create_transition_at_position(position: Vector2) -> Transition:
	var transition: Transition = TransitionScene.instantiate()
	transition.index = transitions.size()
	transition.position = position
	
	transition.set_element_name("t" + str(transition.index + 1))
	add_child(transition)
	
	transitions.append(transition)
	return transition


func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_node = _get_node_at_position(event.position)
			
			if clicked_node != null:
				if is_connect_mode_enabled:
					_handle_node_selection(clicked_node)
				# Не создаем новый узел, если кликнули по существующему
			else:
				if is_place_mode_enabled:
					_create_place_at_position(event.position)
				elif is_transition_mode_enabled:
					_create_transition_at_position(event.position)
				elif is_connect_mode_enabled:
					pass  # Ничего не делаем
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var mouse_pos = event.position
				if is_delete_mode_enabled:
					var node = _get_node_at_position(mouse_pos)
					if node != null:
						_delete_node(node)
					return

func update_connections() -> void:
	print("update_connections() called")
	for connection in connections:
		var from_node = connection["from_node"]
		var to_node = connection["to_node"]
		var line = connection["line"]
		line.set_point_position(0, from_node.global_position)
		line.set_point_position(1, to_node.global_position)

func _get_node_at_position(position: Vector2) -> Node:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 0x7FFFFFFF  # Проверять все слои
	query.exclude = []
	
	var result = space_state.intersect_point(query)
	for item in result:
		var collider = item.collider
		if collider != null:
			var parent_node = collider.get_parent()
			if parent_node is Place or parent_node is Transition:
				return parent_node
			var grandparent_node = parent_node.get_parent()
			if grandparent_node is Place or grandparent_node is Transition:
				return grandparent_node
	return null
	
func _handle_node_selection(node: Node) -> void:
	if selected_node == null:
		selected_node = node
		print("First node selected: ", node.name)
	else:
		# Соединяем два узла
		_connect_nodes(selected_node, node)
		# Устанавливаем соединение на узлах
		selected_node.set_connected(true)
		node.set_connected(true)
		# Сбрасываем выбранный узел
		selected_node = null
		
func _connect_nodes(node_a: Node, node_b: Node) -> void:
	# Создаём соединение между узлами
	_draw_connection(node_a as Node2D, node_b as Node2D)
	# Обновляем списки входов и выходов для переходов и мест
	if node_a is Place and node_b is Transition:
		# Добавляем в массивы (если у вас хранится Array для связей)
		node_b.input_places.append(node_a)
		# Записываем вес в словарь input_weights
		node_b.add_input_place(node_a.index, 1.0)
		
	elif node_a is Transition and node_b is Place:
		# Добавляем в массивы (если у вас хранится Array для связей)
		node_a.output_places.append(node_b)
		# Записываем вес в словарь output_weights
		node_a.add_output_place(node_b.index, 1.0)
		
	elif node_a is Place and node_b is Place:
		print("Connection between two places is not standard for Petri nets.")
		pass
		
	elif node_a is Transition and node_b is Transition:
		print("Connection between two transitions is not standard for Petri nets.")
		pass
		
	else:
		print("Unsupported connection type.")

func _connect_nodes_load(a: Node2D, b: Node2D, is_input: bool) -> void:
	# Предположим, a - Place, b - Transition, и is_input=true => (Place -> Transition)
	# Иначе (Transition -> Place).
	if a is Place and b is Transition and is_input:
		var place = a
		var trans = b
		# Добавляем в trans.input_places
		if not trans.input_places.has(place):
			trans.input_places.append(place)
		# Установим weight, если нужно (вдруг 1.0 по умолчанию)
		if not trans.input_weights.has(place.index):
			trans.input_weights[place.index] = 1.0
		# Рисуем стрелку
		_draw_connection(place, trans)
	
	elif a is Transition and b is Place and not is_input:
		var trans = a
		var place = b
		if not trans.output_places.has(place):
			trans.output_places.append(place)
		if not trans.output_weights.has(place.index):
			trans.output_weights[place.index] = 1.0
		_draw_connection(trans, place)

func _draw_connection(a: Node2D, b: Node2D) -> void:
	# 1) Создаём узел, который будет хранить всё, что связано со стрелкой
	var arrow_node = Node2D.new()
	add_child(arrow_node)  # Обычно добавляем в $Connections или под Main
	arrow_node.add_to_group("connections")  # Группа "connections"

	# 2) Вычисляем глобальные координаты начала и конца
	var start_pos = a.global_position
	var end_pos = b.global_position

	# 3) Создаём Line2D для основной линии
	var line = Line2D.new()
	line.default_color = Color.WHITE  # Цвет линии
	line.width = 2.0                 # Толщина
	# Точки нужно добавлять в локальные координаты arrow_node,
	# то есть конвертировать из глобальных:
	line.add_point(arrow_node.to_local(start_pos))
	line.add_point(arrow_node.to_local(end_pos))
	
	arrow_node.add_child(line)

	# 4) Создаём Polygon2D для наконечника стрелки
	var arrow_tip = Polygon2D.new()
	# Простой треугольник в локальных координатах:
	arrow_tip.polygon = [
		Vector2(0, 0),
		Vector2(-10, 10),
		Vector2(-10, -10)
	]
	arrow_tip.color = Color.WHITE

	# Ставим наконечник в конец стрелки
	var arrow_factor = 0.8  # 0.5 означает ровно середину линии
	var arrow_pos = start_pos + (end_pos - start_pos) * arrow_factor
	arrow_tip.position = arrow_node.to_local(arrow_pos)


	# Поворачиваем наконечник на угол, соответствующий вектору (end - start)
	var direction = (end_pos - start_pos).angle()
	arrow_tip.rotation = direction
	
	arrow_node.add_child(arrow_tip)

func _on_fire_button_pressed() -> void:
	if selected_transition_to_fire != null:
		selected_transition_to_fire.try_fire()
	else:
		print("No transition selected to fire.")


func _on_start_simulation_pressed() -> void:
	var simulation_active = true
	#while simulation_active:
		#simulation_active = false
		#for node in get_children():
			#if node is Transition:
				#var can_fire = node.try_fire()
				#if can_fire:
					#simulation_active = true
	while simulation_active:
		simulation_active = false
	for t in transitions:
		if t.try_fire():
			t.fire_transition()
			simulation_active = true

func _delete_node(node: Node) -> void:
	if node is Place:
		# Удаляем из массива places
		places.erase(node)
		# Удаляем все связи, где этот place участвует
		_remove_place_from_transitions(node)
		node.queue_free()
# Optionally - если рисуем связи заново, вызовем _update_connections()
		_update_connections()
	elif node is Transition:
		transitions.erase(node)
		# Удаляем связи, где этот transition участвует
		#_remove_transition_references(node)
		node.queue_free()
		_update_connections()

func _remove_place_from_transitions(place: Place) -> void:
	for t in transitions:
		if place.index in t.input_weights:
			t.input_weights.erase(place.index)
		if place.index in t.output_weights:
			t.output_weights.erase(place.index)
		if place in t.input_places:
			t.input_places.erase(place)
		if place in t.output_places:
			t.output_places.erase(place)
	var i = places.find(place)
	if i >= 0:
		places[i] = null
	place.queue_free()
	_update_connections()

func _delete_transition(tr: Transition) -> void:
	# Убираем этот переход из массива transitions
	transitions.erase(tr)
	tr.queue_free()
	# Перерисовываем связи
	_update_connections()

#Fuzzy Logic Incidence
func build_incidences() -> Dictionary:
	var m: int = places.size()
	var n: int = transitions.size()
	
	# Создаём матрицы Pre и Post размером m x n, заполненные нулями
	var pre := []
	var post := []
	for i in range(n):
		pre.append([])
		post.append([])
		for j in range(m):
			pre[i].append(0.0)
			post[i].append(0.0)

# Заполняем
	for i in range(n):
		var t = transitions[i]
		# Заполнение Pre
		for place_index in t.input_weights.keys():
			pre[i][place_index] = float(t.input_weights[place_index])
		# Заполнение Post
		for place_index in t.output_weights.keys():
			post[i][place_index] = float(t.output_weights[place_index])
	
	print("places.size() = ", places.size(), " type=", typeof(places.size()))
	print("transitions.size() = ", transitions.size(), " type=", typeof(transitions.size()))

	return {
		"pre": pre,
		"post": post
		}
		

func _on_show_matrices_button_pressed():
	var incidences = build_incidences()
	var pre_matrix = incidences["pre"]
	var post_matrix = incidences["post"]
	var matrix_window = Window.new()
	matrix_window.title = "Incidence Matrices"
	matrix_window.size = Vector2(400, 300)
	matrix_window.position = get_viewport().get_visible_rect().size * 0.5 - matrix_window.size * 0.5

	matrix_window.close_requested.connect(
		Callable(self, "_on_matrix_window_close_requested").bind(matrix_window)
		)

	# Добавляем TabContainer, чтобы вывести Pre и Post на разных вкладках
	var tab_container = TabContainer.new()
	matrix_window.add_child(tab_container)

	# Создаём вкладку для Pre
	var pre_tab = _build_matrix_view(pre_matrix, "Pre")
	tab_container.add_child(pre_tab)
	var pre_idx = tab_container.get_tab_count() - 1
	tab_container.set_tab_title(pre_idx, "Pre Matrix")
	
	# Создаём вкладку для Post
	var post_tab = _build_matrix_view(post_matrix, "Post")
	tab_container.add_child(post_tab)
	var post_idx = tab_container.get_tab_count() - 1
	tab_container.set_tab_title(post_idx, "Post Matrix")

	# Добавляем окно в сцену
	add_child(matrix_window)
	matrix_window.popup()


func _on_matrix_window_close_requested(window: Window) -> void:
	# Закрываем (удаляем) окно
	window.queue_free()
	
func _build_matrix_view(matrix: Array, matrix_name: String) -> Control:
	# Предположим, matrix — это Array[Array[float]]
	# Вычисляем размеры
	var row_count = matrix.size()
	var col_count = 0
	if row_count > 0:
		col_count = matrix[0].size()

	# Создаём контейнер, который будет родителем GridContainer
	var container = VBoxContainer.new()
	container.name = matrix_name + "_Container"

	# Добавим название или какую-то надпись
	var label_title = Label.new()
	label_title.text = matrix_name + " Matrix (" + str(row_count) + " x " + str(col_count) + ")"
	label_title.theme_type_variation = "title"  # Для красоты, если хотите
	container.add_child(label_title)

	# GridContainer для ячеек
	var grid = GridContainer.new()
	grid.columns = col_count  # Устанавливаем число столбцов
	container.add_child(grid)

	# Проходим по строкам и столбцам
	for i in range(row_count):
		for j in range(col_count):
			var cell_label = Label.new()
			cell_label.text = str(matrix[i][j])  # Выводим вещественное значение
			cell_label.autowrap_mode = 0
			cell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			# Можно задать min_size или theme_override для оформления
			grid.add_child(cell_label)
	
	return container

#Этот связан с обновлением матрицы после изменений
func _refresh_matrices_display():
	var inc = build_incidences()
	var pre = inc["pre"]
	var post = inc["post"]

	# Формируем строку
	var text_str = "Pre matrix:\n"
	for i in range(pre.size()):
		text_str += str(pre[i]) + "\n"
	
	text_str += "\nPost matrix:\n"
	for i in range(post.size()):
		text_str += str(post[i]) + "\n"

#@#############################Saving system code#####################################
func save_network(file_path: String):
	var data = {
		"places": [],
		"transitions": []
	}

	# Собираем данные о местах
	for place in places:
		var place_dict = {
			"index": place.index,
			"position": [place.position.x, place.position.y],
			"token_value": place.token_value,
			"element_name": place.element_name
		}
		data["places"].append(place_dict)

	# Собираем данные о переходах
	for transition in transitions:
		var transition_dict = {
			"index": transition.index,
			"position": [transition.position.x, transition.position.y],
			"firing_threshold": transition.firing_threshold,
			"element_name": transition.element_name,
			"input_weights": {},
			"output_weights": {}
		}
		
		data["transitions"].append(transition_dict)
		# Преобразуем словари input_weights и output_weights в Dict[str->float]
		var in_w = {}
		for place_idx in transition.input_weights.keys():
			in_w[str(place_idx)] = transition.input_weights[place_idx]
		
		var out_w = {}
		for place_idx in transition.output_weights.keys():
			out_w[str(place_idx)] = transition.output_weights[place_idx]
			
		transition_dict["input_weights"] = in_w
		transition_dict["output_weights"] = out_w
		
		data["transitions"].append(transition_dict)

	# Превращаем data в JSON
	var json_str = JSON.stringify(data, "  ")  # второй аргумент - отступ (не обязательно)
	
	var file = FileAccess.open(file_path, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		print("Network saved to: ", file_path)
	else:
		print("Cannot open file for writing: ", file_path)

func load_network(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	if file == null:
		print("Cannot open file for reading: ", file_path)
		return
		
	var json_str = file.get_as_text()
	file.close()
	
	var parser = JSON.new()
	# parse(...) вернёт int (код ошибки), а не JSONParseResult
	var error_code = parser.parse(json_str)
	if error_code != OK:
		# Выводим сообщение об ошибке через parser.get_error_message()
		var err_msg = parser.get_error_message()
		var err_line = parser.get_error_line()
		print("JSON parse error at line ", err_line, ": ", err_msg)
		return
		
	var data = parser.get_data()
	if not data.has("places") or not data.has("transitions"):
		print("Invalid file format: no 'places' or 'transitions'")
		return

	# Удаляем все текущие элементы
	# Это значит: очистить массив places, transitions, возможно удалить из сцены...
	_clear_network()

	# Загружаем places
	for place_dict in data["places"]:
		var p = _create_place_at_position(Vector2(
			place_dict["position"][0],
			place_dict["position"][1]
		))
		p.index = place_dict["index"]
		p.token_value = place_dict["token_value"]
		p.element_name = place_dict["element_name"]

	# Загружаем массив transitions
	for t_dict in data["transitions"]:
		var t = _create_transition_at_position(Vector2(
			t_dict["position"][0],
			t_dict["position"][1]
			))
		t.index = t_dict["index"]
		t.firing_threshold = t_dict["firing_threshold"]
		t.element_name = t_dict["element_name"]

		# Восстанавливаем input_weights/ output_weights
		var in_w_dict = t_dict["input_weights"]
		for k in in_w_dict.keys():
			var place_idx = int(k)
			var w = float(in_w_dict[k])
			t.input_weights[place_idx] = w
			if w != 0.0:   # Если вы храните нулевые => игнор?
				# Сформируем связь и массив input_places
				t.input_places.append(places[place_idx])
		
		var out_w_dict = t_dict["output_weights"]
		for k in out_w_dict.keys():
			var place_idx = int(k)
			var w = float(out_w_dict[k])
			t.output_weights[place_idx] = w
			if w != 0.0:
				t.output_places.append(places[place_idx])

	_rebuild_connections_after_load()
	
	for p in places:
		p.update_label()
		p._update_name_label()
	for tr in transitions:
		tr.update_label()
		tr._update_name_label()
		tr._update_matrix_label()
	
	print("Network loaded from: ", file_path)

func _rebuild_connections():
	for transition in transitions:
		for place_idx in transition.input_weights.keys():
			if transition.input_weights[place_idx] != 0.0:
				var place = places[place_idx]
				# Вместо прямого _draw_connection мы вызываем _connect_nodes, 
				# который делает и визуальное, и логическое соединение
				_connect_nodes_load(place, transition, true)
		for place_idx in transition.output_weights.keys():
			if transition.output_weights[place_idx] != 0.0:
				var place = places[place_idx]
				_connect_nodes_load(place, transition, false)

func _rebuild_connections_after_load():
	# Удаляем (или не удаляем) старые линии, если у вас они были отдельно
	# Если вы храните массив connections, почистите его, queue_free() и т.д.
	var connections_node = $Connections
	for child in connections_node.get_children():
		child.queue_free()
	# Проходим по каждому переходу
	for t in transitions:
		# Для каждого места, указанного как вход (в t.input_weights)
		for place_idx in t.input_weights.keys():
			var w = t.input_weights[place_idx]
			if w != 0.0:
				# Находим место
				var p = places[place_idx]
				# Вызываем метод, который делает "реальное" подключение: place -> transition
				_connect_nodes_load(p, t, true)

		# Для каждого места, указанного как выход (в t.output_weights)
		for place_idx in t.output_weights.keys():
			var w = t.output_weights[place_idx]
			if w != 0.0:
				var p = places[place_idx]
				_connect_nodes_load(t, p, false)

func _clear_network() -> void:
	# Удаляем все места (очищаем массив places)
	for p in places:
		p.queue_free()
	places.clear()

	# Удаляем все переходы (очищаем массив transitions)
	for t in transitions:
		t.queue_free()
	transitions.clear()
	
	var con_nodes = get_tree().get_nodes_in_group("connections")
	for c in con_nodes:
		c.queue_free()
	
func _on_save_button_pressed() -> void:
	file_dialog_save.popup()

func _on_file_save_selected(file_path: String) -> void:
	save_network(file_path)

func _on_load_button_pressed() -> void:
	file_dialog_load.popup()

func _on_file_load_selected(file_path: String) -> void:
	load_network(file_path)

#Update connections
func _update_connections() -> void:
	# Удалить старые линии
	var con_nodes = get_tree().get_nodes_in_group("connections")
	for c in con_nodes:
		c.queue_free()
	# Пройти по всем transitions, для каждого input_weights => (place -> transition),
	# output_weights => (transition -> place). Вызываем _draw_connection
	for t in transitions:
		for place_idx in t.input_weights.keys():
			if t.input_weights[place_idx] != 0.0:
				_draw_connection(places[place_idx], t)
		for place_idx in t.output_weights.keys():
			if t.output_weights[place_idx] != 0.0:
				_draw_connection(t, places[place_idx])
