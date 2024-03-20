extends Node

@export var target: Node3D
@export var speed: float = 1.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target != null:
		target.rotate_object_local(Vector3.UP, delta * speed)
