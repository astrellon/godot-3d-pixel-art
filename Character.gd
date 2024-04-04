extends Node3D

@export var graphic: AnimatedSprite3D
@export var camera: Camera3D

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

	# var query_params = NavigationPathQueryParameters3D.new()
	# var query_result = NavigationPathQueryResult3D.new();

	# query_params.map = get_world_3d().get_navigation_map()
	# query_params.start_position = global_position
	# query_params.target_position

const RAY_LENGTH = 1000.0
var _prev_pressed = false

func _physics_process(_delta):
	var pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var click = false
	if pressed && !_prev_pressed:
		click = true
	_prev_pressed = pressed
	
	if !click:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	print("Clicked at: " + str(mouse_pos))
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var ray_cast = PhysicsRayQueryParameters3D.create(from, to)
	ray_cast.collide_with_areas = true

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_cast)

	if result:
		print("Hit: " + str(result['position']))
	else:
		print("No raycast hit")


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

		#var pos = position
		#var cam = get_viewport().get_camera_3d()
		#var dist = pos.distance_to(cam.position)
		#var screen_pos = cam.unproject_position(pos)
		#var rounded = screen_pos.round()
		#var new_pos = cam.project_position(rounded, dist)
		#position = new_pos

	var sprite_name = create_animation_name(new_move_speed, new_facing)
	if sprite_name != prev_animation:
		graphic.play(sprite_name)
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
