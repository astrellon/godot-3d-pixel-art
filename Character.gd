extends AnimatedSprite3D

const MOVE_SPEED = 2.5
enum MoveDirection {
	XPos, XNeg,
	ZPos, ZNeg
}
enum MoveSpeed {
	Idle, Walking
}

var facing: MoveDirection = MoveDirection.XNeg
var move_speed: MoveSpeed = MoveSpeed.Idle
var prev_animation: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var move = Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		move += Vector3.FORWARD
	if Input.is_action_pressed("ui_right"):
		move += Vector3.BACK
	if Input.is_action_pressed("ui_up"):
		move += Vector3.RIGHT
	if Input.is_action_pressed("ui_down"):
		move += Vector3.LEFT
	
	if move:
		move = move.normalized() * delta * MOVE_SPEED
	
	do_move(move)


func do_move(delta: Vector3):
	var new_facing = facing
	var new_move_speed = MoveSpeed.Idle
	
	if delta.x > 0:
		new_facing = MoveDirection.XPos
	elif delta.x < 0:
		new_facing = MoveDirection.XNeg
	elif delta.z > 0:
		new_facing = MoveDirection.ZPos
	elif delta.z < 0:
		new_facing = MoveDirection.ZNeg
	
	if delta:
		new_move_speed = MoveSpeed.Walking
		global_translate(delta)

	var sprite_name = create_animation_name(new_move_speed, new_facing)
	if sprite_name != prev_animation:
		play(sprite_name)
		prev_animation = sprite_name
		
	facing = new_facing
	move_speed = new_move_speed


func create_animation_name(move_speed: MoveSpeed, facing: MoveDirection):
	var sprite_name = "idle"
	if move_speed == MoveSpeed.Walking:
		sprite_name = "walk"
		
	sprite_name += "_"
	
	if facing == MoveDirection.XNeg:
		sprite_name += "x_neg"
	if facing == MoveDirection.XPos:
		sprite_name += "x_pos"
	if facing == MoveDirection.ZNeg:
		sprite_name += "z_neg"
	if facing == MoveDirection.ZPos:
		sprite_name += "z_pos"
		
	return sprite_name
