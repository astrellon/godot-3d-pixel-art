extends AnimatedSprite3D

const MOVE_SPEED = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var move = Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		move += Vector3.LEFT * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_right"):
		move += Vector3.RIGHT * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_up"):
		move += Vector3.FORWARD * delta * MOVE_SPEED
	if Input.is_action_pressed("ui_down"):
		move += Vector3.BACK * delta * MOVE_SPEED
		
	if move:
		global_translate(move)
