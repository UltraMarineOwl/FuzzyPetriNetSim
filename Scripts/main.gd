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
var mode_button_group: ButtonGroup = ButtonGroup.new()

var is_place_mode_enabled: bool = false
var is_transition_mode_enabled: bool = false
var is_connect_mode_enabled: bool = false

var selected_place: Place = null
var selected_transition: Transition = null

var connections = []  # Список словарей с информацией о соединениях


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
	add_child(place)
	place.position = position
	place.token_value = 0.0  # Начальное значение метки

func _create_transition_at_position(position: Vector2) -> void:
	var transition: Transition = TransitionScene.instantiate()
	add_child(transition)
	transition.position = position

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
	
func _handle_node_selection(node: Node) -> void:
	if node is Place:
		if selected_transition != null:
			# Связываем переход и место
			selected_transition.output_places.append(node)
			_draw_connection(selected_transition, node)
			# Сбрасываем выбор
			selected_transition = null
			print("Connected Transition to Place")
		else:
			selected_place = node
			print("Selected Place")
	elif node is Transition:
		if selected_place != null:
			# Связываем место и переход
			node.input_places.append(selected_place)
			_draw_connection(selected_place, node) # Рисуется линии
			# Сбрасываем выбор
			selected_place = null
			print("Connected Place to Transition")
		else:
			selected_transition = node
			print("Selected Transition")

func _draw_connection(from_node: Node2D, to_node: Node2D) -> void:
	var line = Line2D.new()
	line.default_color = Color.WHITE
	line.width = 2
	line.add_point(from_node.position)
	line.add_point(to_node.position)
	connections_node.add_child(line)


func _on_fire_button_pressed() -> void:
	if selected_transition != null:
		selected_transition.try_fire()
	else:
		print("No transition selected to fire.")
