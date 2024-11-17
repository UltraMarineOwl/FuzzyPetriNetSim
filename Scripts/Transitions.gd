# Scripts/Transition.gd
extends Node2D

var input_places: Array[Node2D] = []
var output_places: Array[Node2D] = []
var firing_threshold = 0.5  # Порог срабатывания перехода

func _ready():
	update_label()

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
		place.token_value -= firing_threshold  # Или другое правило уменьшения
		place.update_label()
	for place in output_places:
		place.token_value += firing_threshold  # Или другое правило увеличения
		place.update_label()
