# Scripts/Transition.gd
extends Node2D

class_name Transition

var input_places: Array[Place] = []
var output_places: Array[Place] = []
var firing_threshold = 0.5  # Порог срабатывания перехода

var is_dragging: bool = false
var drag_offset: Vector2
var main
var is_connected: bool = false

func _ready():
	update_label()
	if main == null:
		main = get_parent()

func update_label():
	$Label.text = "%.2f" % firing_threshold

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
	elif event is InputEventMouseMotion and is_dragging:
		position = get_global_mouse_position() + drag_offset
		_update_connections()

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
