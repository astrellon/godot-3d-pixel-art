extends Control

signal input_event(event: InputEvent)

func _input(event: InputEvent):
	input_event.emit(event)
