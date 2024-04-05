extends Node3D

@export var graphic: AnimatedSprite3D
@export var camera: Camera3D

const RAY_LENGTH = 1000.0
const MOVE_SPEED = 2.5

enum MoveDirection {
	XPos, XNeg,
	ZPos, ZNeg
}
enum MoveSpeed {
	Idle, Walking
}

var _facing := MoveDirection.XNeg
var _move_speed := MoveSpeed.Idle
var _prev_animation : = ""
var _nav_path := PackedVector3Array()
var _nav_index := 0
var _navigating := false
var _clicked_at := Vector2.ZERO
var _clicked := false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#var move = Vector3.ZERO
	#if Input.is_action_pressed("ui_left"):
		#move += Vector3.FORWARD
	#if Input.is_action_pressed("ui_right"):
		#move += Vector3.BACK
	#if Input.is_action_pressed("ui_up"):
		#move += Vector3.RIGHT
	#if Input.is_action_pressed("ui_down"):
		#move += Vector3.LEFT
#
	#if move:
		#move = move.normalized() * delta * MOVE_SPEED
#
	#do_move(move)

func _process(delta: float) -> void:
	var move = Vector3.ZERO
	if _navigating:
		if _nav_index < len(_nav_path):
			var to_next_point = _nav_path[_nav_index] - global_position
			var to_next_dist = to_next_point.length()
			if to_next_dist < 0.1:
				_nav_index += 1
			else:
				move = to_next_point.limit_length(MOVE_SPEED * delta)
		else:
			_navigating = false

	_do_move(move)


func _physics_process(_delta):
	if !_clicked:
		return

	_clicked = false
	var mouse_pos = _clicked_at
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var ray_cast = PhysicsRayQueryParameters3D.create(from, to)
	ray_cast.collide_with_areas = true

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_cast)

	if result:
		var hit_position = result['position']
		_calculate_nav(hit_position)
	else:
		print("No raycast hit")


func _calculate_nav(target:Vector3):
	var query_params = NavigationPathQueryParameters3D.new()
	var query_result = NavigationPathQueryResult3D.new();

	query_params.map = get_world_3d().get_navigation_map()
	query_params.start_position = global_position
	query_params.target_position = target

	NavigationServer3D.query_path(query_params, query_result)
	_nav_path = query_result.get_path()
	_nav_index = 0
	_navigating = true


func _do_move(delta: Vector3):
	var new_facing = _facing
	var new_move_speed = MoveSpeed.Idle

	if delta:
		var xDot = Vector3.RIGHT.dot(delta)
		var zDot = Vector3.FORWARD.dot(delta)

		if abs(xDot) > abs(zDot):
			if xDot > 0:
				new_facing = MoveDirection.XPos
			else:
				new_facing = MoveDirection.XNeg
		else:
			if zDot < 0:
				new_facing = MoveDirection.ZPos
			else:
				new_facing = MoveDirection.ZNeg

		new_move_speed = MoveSpeed.Walking
		global_translate(delta)

	var sprite_name = _create_animation_name(new_move_speed, new_facing)
	if sprite_name != _prev_animation:
		graphic.play(sprite_name)
		_prev_animation = sprite_name

	_facing = new_facing
	_move_speed = new_move_speed


static func _create_animation_name(move_speed: MoveSpeed, facing: MoveDirection):
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


func _on_game_input_event(event: InputEvent):
	if event is InputEventMouseButton && event.button_index == 1 && event.pressed:
		_clicked_at = event.position * 0.5
		_clicked = true
