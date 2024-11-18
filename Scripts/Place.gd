# Scripts/Place.gd
extends Node2D
class_name Place

var token_value: float = 0.0  # Значение метки (от 0.0 до 1.0)

func _ready() -> void:
	update_label()

func update_label() -> void:
	$Label.text = "%.2f" % token_value

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.doubleclick:
			# Открыть интерфейс для изменения token_value
			pass  # Реализуйте по необходимости
