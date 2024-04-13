extends Control

@export var target: Character = null
@export var camera: Camera3D = null
@export var render_size: TextureRect = null
@export var viewport: SubViewport = null
@export var pixel_size := 2.0
@export var building_file: PackedScene
@export var building_smoke_file: PackedScene
@export var main_scene: Node3D
@export var pointer: Node3D

signal input_event(event: InputEvent)


enum ClickMode { None, Build }


var _clicked_at := Vector2.ZERO
var _mouse_pos := Vector2.ZERO
var _click_mode := ClickMode.None
var _clicked := false
var _window_size := Vector2(1280, 720)
var _pointer_height := 0.25


func _ready() -> void:
	get_tree().root.size_changed.connect(_on_window_resize)
	_on_window_resize()

func _on_window_resize() -> void:
	_window_size = get_tree().root.size

	var scaled_size = _window_size / pixel_size
	var ortho_size = scaled_size.y / 360.0 * 10.0
	camera.size = ortho_size
	viewport.size = scaled_size
	RenderingServer.global_shader_parameter_set("screen_size", scaled_size)


func _input(event: InputEvent):
	input_event.emit(event)
	if event is InputEventMouseMotion:
		_mouse_pos = event.position * _window_size / render_size.size / pixel_size
		
	if event is InputEventMouseButton:
		_mouse_pos = event.position * _window_size / render_size.size / pixel_size
		if event.button_index == MOUSE_BUTTON_LEFT && event.is_released():
			_clicked_at = _mouse_pos
			_clicked = true
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP && event.is_released():
			_pointer_height = max(0.0, _pointer_height - 0.05)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.is_released():
			_pointer_height = min(10.0, _pointer_height + 0.05)


func _handle_mouse_ray(mouse_pos: Vector2) -> Dictionary:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100.0
	var ray_cast = PhysicsRayQueryParameters3D.create(from, to)
	ray_cast.collide_with_areas = true

	var space_state = camera.get_world_3d().direct_space_state
	return space_state.intersect_ray(ray_cast)
	

func _physics_process(_delta: float) -> void:
	var ray_result = _handle_mouse_ray(_mouse_pos)
	if pointer && ray_result:
		pointer.global_position = ray_result['position'] + Vector3.UP * _pointer_height
		
	if !_clicked:
		return

	_clicked = false

	if ray_result:
		if _click_mode == ClickMode.Build:
			_handle_click_build(ray_result)
		elif _click_mode == ClickMode.None:
			_handle_click_general(ray_result)
	else:
		print("No raycast hit")

func _handle_click_build(hit_result) -> void:
	_click_mode = ClickMode.None
	var hit_position = hit_result['position']
	var new_building = building_file.instantiate()
	if new_building is Node3D:
		new_building.position = hit_position

	var place_smoke = building_smoke_file.instantiate()
	if place_smoke is Node3D:
		place_smoke.position = hit_position
		
	main_scene.add_child(new_building)
	main_scene.add_child(place_smoke)
	
	var nav_region = find_child("NavigationRegion3D")
	if nav_region is NavigationRegion3D:
		print("Updating nav region")
		nav_region.bake_navigation_mesh()
	else:
		print("Could not find nav region!")

func _handle_click_general(hit_result) -> void:
	var hit = hit_result['collider']
	var changed_target := false
	if hit:
		var parent = hit.get_parent()
		if parent is Character:
			_change_target(parent)
			changed_target = true

	if !changed_target && target:
		var hit_position = hit_result['position']
		target.calculate_nav(hit_position)


func _change_target(new_target: Character) -> void:
	if target:
		target.is_selected = false

	if new_target:
		new_target.is_selected = true

	target = new_target


func _on_build_click() -> void:
	_clicked = false
	_click_mode = ClickMode.Build
