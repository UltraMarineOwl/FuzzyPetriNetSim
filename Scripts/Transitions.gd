# Scripts/Transition.gd
extends Node2D

class_name Transition

var input_places: Array[Node2D] = []
var output_places: Array[Node2D] = []
var firing_threshold = 0.5  # Порог срабатывания перехода

func _ready():
	update_label()
	set_process_input(true)

func update_label():
	$Label.text = "Transition"

func try_fire():
	var can_fire = true
	for place in input_places:
		if place.token_value < firing_threshold:
			can_fire = false
			break
	if can_fire:
		fire_transition()

func fire_transition():
	# Обновляем значения меток
	for place in input_places:
		place.token_value = max(0.0, place.token_value - firing_threshold)
		place.update_label()
	for place in output_places:
		place.token_value = min(1.0, place.token_value + firing_threshold)
		place.update_label()

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.doubleclick:
			# Открыть интерфейс для изменения firing_threshold
			pass  # Реализуйте по необходимости
