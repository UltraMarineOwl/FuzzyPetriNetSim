# Scripts/Place.gd
extends Node2D
class_name Place

var token_value: float = 0.0  # Значение метки (от 0.0 до 1.0)
var is_dragging: bool = false
var drag_offset: Vector2
var main

func _ready() -> void:
	update_label()
	if main == null:
		main = get_parent()

func update_label() -> void:
	$Label.text = "%.2f" % token_value

func _input(event: InputEvent) -> void:
	if main != null and main.is_connect_mode_enabled:
		return  # Не перетаскиваем узлы в режиме связывания
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			if event.pressed and _is_mouse_over(mouse_pos):
				_change_token_value()
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


func _update_connections() -> void:
	# Уведомляем родителя о перемещении для обновления линий
	#if get_parent().has_method("update_connections"):
	#	get_parent().update_connections()
	var parent = get_parent()
	print("Parent of ", self.name, " is ", parent.name)
	if parent.has_method("update_connections"):
		print("Calling update_connections() from ", self.name)
		parent.update_connections()
	else:
		print("Parent does not have method update_connections()")

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.doubleclick:
			# Открыть интерфейс для изменения token_value
			pass  # Реализуйте по необходимости
