class_name Character extends Node3D

@export var graphic: Array[AnimatedSprite3D] = []

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


func calculate_nav(target:Vector3):
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
		for g in graphic:
			g.play(sprite_name)
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
