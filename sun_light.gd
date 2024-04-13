class_name SunLight
extends DirectionalLight3D

@export var time_of_day := 12.0 :
	get:
		return time_of_day
	set(value):
		time_of_day = fmod(value, 24.0)
@export var speed := 0.5

var _original_rotation := Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _ready():
	_original_rotation = rotation
	_update_rotation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_of_day += delta * speed
	_update_rotation()
	

func _update_rotation() -> void:
	var radians = time_of_day / 12.0 * PI + PI * 0.5
	rotation = _original_rotation
	rotate_object_local(Vector3.RIGHT, radians)
