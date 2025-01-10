# Scripts/Main.gd
extends Node2D

var PlaceScene = preload("res://Scenes/Place.tscn")
var TransitionScene = preload("res://Scenes/Transitions.tscn")

@onready var connections_node: Node2D = $Connections

# Переменные для кнопок режимов
var place_mode_button: CheckButton
var transition_mode_button: CheckButton
var connect_mode_button: CheckButton
var fire_button: Button  # Если необходимо
var show_matrix: Button
var mode_button_group: ButtonGroup = ButtonGroup.new()

var is_place_mode_enabled: bool = false
var is_transition_mode_enabled: bool = false
var is_connect_mode_enabled: bool = false

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
	var connect_mode_button = CheckButton.new()
	connect_mode_button.text = "Connect Nodes"
	connect_mode_button.toggle_mode = true
	connect_mode_button.button_group = mode_button_group
	connect_mode_button.position = Vector2(10, 100)
	add_child(connect_mode_button)
	connect_mode_button.toggled.connect(_on_connect_mode_toggled)
	
	# Добавляем кнопку для срабатывания перехода
	fire_button = Button.new()
	fire_button.text = "Fire Transition"
	fire_button.position = Vector2(10, 150)
	add_child(fire_button)
	fire_button.pressed.connect(_on_fire_button_pressed)
	
	show_matrix = Button.new()
	show_matrix.text = "Show Matrix"
	show_matrix.position = Vector2(10, 200)
	add_child(show_matrix)
	show_matrix.pressed.connect(_on_show_matrices_button_pressed)
	
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

func _create_place_at_position(position: Vector2) -> void:
	var place: Place = PlaceScene.instantiate()
	place.index = places.size()  # Индекс места = текущий размер массива
	place.position = position
	
	# Формируем название: p1, p2, p3 и т. д.
	# Например: "p" + str(place.index + 1)
	place.set_element_name("p" + str(place.index + 1))
	add_child(place)
	
	#place.token_value = 0.0  # Начальное значение метки
	places.append(place) #добавляю запись для места

func _create_transition_at_position(position: Vector2) -> void:
	var transition: Transition = TransitionScene.instantiate()
	transition.index = transitions.size()
	transition.position = position
	
	transition.set_element_name("t" + str(transition.index + 1))
	add_child(transition)
	
	transitions.append(transition)

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
	

#func _handle_node_selection(node: Node) -> void:
	#if node is Place:
		#if selected_transition != null:
			## Связываем переход и место
			#selected_transition.output_places.append(node)
			#_draw_connection(selected_transition, node)
			## Сбрасываем выбор
			#selected_transition = null
			#print("Connected Transition to Place")
		#else:
			#selected_place = node
			#print("Selected Place")
	#elif node is Transition:
		#if selected_place != null:
			## Связываем место и переход
			#node.input_places.append(selected_place)
			#_draw_connection(selected_place, node) # Рисуется линии
			## Сбрасываем выбор
			#selected_place = null
			#print("Connected Place to Transition")
		#else:
			#selected_transition = node
			#print("Selected Transition")

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

func _draw_connection(a: Node2D, b: Node2D) -> void:
	# 1) Создаём узел, который будет хранить всё, что связано со стрелкой
	var arrow_node = Node2D.new()
	add_child(arrow_node)  # Обычно добавляем в $Connections или под Main

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
	while simulation_active:
		simulation_active = false
		for node in get_children():
			if node is Transition:
				var can_fire = node.try_fire()
				if can_fire:
					simulation_active = true
		# Добавляем небольшую задержку для обновления интерфейса
		#


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
