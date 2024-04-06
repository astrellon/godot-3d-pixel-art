extends Camera3D

@export var target: Node3D
var dir: Vector3 = Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _ready():
	dir = transform.basis.z
	follow_target()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	follow_target()


func follow_target():
	if !target:
		return
	
	#var pos = target.position + dir * 10.0
	#position = pos
	var target_screen = unproject_position(target.position)
	var rounded = target_screen.round()
	var projected = project_position(rounded, 10.0)
	var pos = projected + dir * 10.0
	position = pos
