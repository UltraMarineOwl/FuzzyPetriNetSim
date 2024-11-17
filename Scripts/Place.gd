# Scripts/Place.gd
extends Node2D

var token_value: float = 0.0  # Значение метки (от 0.0 до 1.0)

func _ready() -> void:
	update_label()

func update_label() -> void:
	$Label.text = "%.2f" % token_value
