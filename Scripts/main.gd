# Scripts/Main.gd
extends Node2D

func _ready() -> void:
	var PlaceScene = preload("res://Scenes/Place.tscn")
	var TransitionScene = preload("res://Scenes/Transitions.tscn")

	# Создаем места
	var place1 = PlaceScene.instantiate()
	add_child(place1)
	place1.position = Vector2(100, 200)
	place1.token_value = 0.7

	var place2 = PlaceScene.instantiate()
	add_child(place2)
	place2.position = Vector2(500, 200)

	# Создаем переход
	var transition = TransitionScene.instantiate()
	add_child(transition)
	transition.position = Vector2(300, 200)

	# Устанавливаем связи
	transition.input_places.append(place1)
	transition.output_places.append(place2)

	# Добавляем кнопку для срабатывания перехода
	var fire_button = Button.new()
	fire_button.text = "Fire Transition"
	fire_button.position = Vector2(300, 50)
	add_child(fire_button)
	fire_button.connect("pressed", Callable(self, "_on_fire_button_pressed").bind(transition))

func _on_fire_button_pressed(transition) -> void:
	transition.try_fire()
