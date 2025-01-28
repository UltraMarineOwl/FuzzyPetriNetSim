# Scripts/Place.gd
extends Node2D
class_name Place

var index: int = -1
var element_name: String = ""  # Имя, типа "p1"

var token_value: float = 0.0  # Значение метки (от 0.0 до 1.0)
var is_dragging: bool = false
var drag_offset: Vector2
var main

var is_connected: bool = false
var token_line_edit: LineEdit

func _ready() -> void:
	update_label()
	_update_name_label()
	if main == null:
		main = get_parent()
	

func set_element_name(new_name: String) -> void:
	element_name = new_name
	_update_name_label()

func _update_name_label() -> void:
	# Ищем узел Label, который вы создали в сцене (NameLabel)
	var label_node = $NameLabel
	if label_node != null:
		label_node.text = element_name

func update_label() -> void:
	$Label.text = "%.2f" % token_value

func _input(event: InputEvent) -> void:
	if main != null and main.is_connect_mode_enabled:
		return  # Не перетаскиваем узлы в режиме связывания
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			if event.pressed and _is_mouse_over(mouse_pos):
				is_dragging = true
				drag_offset = position - mouse_pos
			elif not event.pressed:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		position = event.position + drag_offset
		print("Node moved: ", self.name)
		_update_connections()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			if _is_mouse_over(mouse_pos):
				# Открываем окно ввода или увеличиваем значение метки
				_change_token_value()
	if event is InputEventMouseButton and event.double_click:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false
			var mouse_pos = get_global_mouse_position()
			if _is_mouse_over(mouse_pos):
				_prompt_token_value()
	if event is InputEventMouseMotion and is_dragging:
		position = get_global_mouse_position() + drag_offset
		# После изменения позиции, перерисовать линии
		var par = get_parent()
		if par != null and par.has_method("_update_connections"):
			par._update_connections()

func _prompt_token_value() -> void:
		# Создаём окно
	var dialog = Window.new()
	dialog.title = "Set token value"
	dialog.size = Vector2(300, 100)

	# Размещаем окно в центре экрана (необязательно, но удобно)
	dialog.position = get_viewport().get_visible_rect().size * 0.5 - dialog.size * 0.5

	# Создаём контейнер (VBoxContainer), чтобы вертикально расположить элементы
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)

	# Добавляем заголовок-Label
	var label_info = Label.new()
	label_info.text = "Enter token value (0.0 - 1.0):"
	vbox.add_child(label_info)

	# Создаём LineEdit для ввода значения
	var line_edit = LineEdit.new()
	line_edit.text = str(token_value)  # Начальное значение - текущее
	vbox.add_child(line_edit)

	# Создаём кнопку "OK"
	var button_ok = Button.new()
	button_ok.text = "OK"
	# Подключаем сигнал нажатия и передаём через bind() ссылку на диалог и line_edit
	button_ok.pressed.connect(Callable(self, "_on_token_value_ok_pressed").bind(dialog, line_edit))
	vbox.add_child(button_ok)

	# Добавляем окно в сцену (Place.gd - обычно дочерний к main, но можно и get_tree().get_current_scene())
	add_child(dialog)
	dialog.popup()  # Отображаем окно поверх

func _on_token_value_ok_pressed(dialog: Window, line_edit: LineEdit) -> void:
	var text_value = line_edit.text
	# Проверяем, является ли введённое значение корректным числом
	if not text_value.is_valid_float():
		print("Invalid input, please enter a float number.")
		return

	var new_value = text_value.to_float()
	# Если вам нужно ограничить от 0.0 до 1.0:
	new_value = clamp(new_value, 0.0, 1.0)
	
	token_value = new_value
	update_label()

	# Закрываем окно
	dialog.queue_free()

func _on_token_value_confirmed(line_edit: LineEdit) -> void:
	var text = token_line_edit.text
	if not text.is_valid_float():
		print("Invalid input. Please enter a number.")
		return
	var value = text.to_float()
	token_value = clamp(value, 0.0, 1.0)
	update_label()
	token_line_edit.get_parent().queue_free()  # Закрываем окно

func _change_token_value() -> void:
	token_value = min(1.0, token_value + 0.1)
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

func _update_connections() -> void:
	# Уведомляем родителя о перемещении для обновления линий
	#if get_parent().has_method("update_connections"):
	#	get_parent().update_connections()
	var parent = get_parent()
	while parent != null and not parent.has_method("update_connections"):
		parent = parent.get_parent()
	if parent != null:
		parent.update_connections()

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.doubleclick:
			# Открыть интерфейс для изменения token_value
			pass  # Реализуйте по необходимости
