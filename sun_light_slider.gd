extends HSlider

@export var target: SunLight
@export var time_label: Label

var _dragging := false

# Called when the node enters the scene tree for the first time.
func _ready():
	value = target.time_of_day


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !_dragging:
		value = target.time_of_day
	
	var hours = floor(target.time_of_day)
	var minutes = floor(fposmod(target.time_of_day, 1.0) * 60)
	time_label.text = "%02d:%02d" % [hours, minutes]


func _on_drag_ended(value_changed):
	_dragging = false
	if value_changed:
		target.time_of_day = value


func _on_drag_started():
	_dragging = true
