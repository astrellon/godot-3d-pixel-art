extends Control

@export var target: Character = null
@export var camera: Camera3D = null
@export var render_size: TextureRect = null
@export var viewport: SubViewport = null
@export var pixel_size := 2.0

signal input_event(event: InputEvent)

var _clicked_at := Vector2.ZERO
var _clicked := false
var _window_size := Vector2(1280, 720)

func dir(class_instance):
	var output = {}
	var methods = []
	for method in class_instance.get_method_list():
		methods.append(method.name)

	output["METHODS"] = methods

	var properties = []
	for prop in class_instance.get_property_list():
		if prop.type == 3:
			properties.append(prop.name)
			properties.append(str(class_instance[prop.name]))
	output["PROPERTIES"] = properties

	return output
	
func _ready():
	get_tree().root.size_changed.connect(_on_window_resize)
	_on_window_resize()
	
func _on_window_resize():
	_window_size = get_tree().root.size
	
	var scaled_size = _window_size / pixel_size
	var ortho_size = scaled_size.y / 360.0 * 10.0
	camera.size = ortho_size	
	viewport.size = scaled_size
	RenderingServer.global_shader_parameter_set("screen_size", scaled_size)


func _input(event: InputEvent):
	input_event.emit(event)
	if event is InputEventMouseButton && event.button_index == 1 && event.pressed:
		#_clicked_at = event.position * Vector2(640.0 / render_size.size.x, 360.0 / render_size.size.y)
		_clicked_at = event.position * _window_size / render_size.size / pixel_size
		_clicked = true

func _physics_process(delta):
	if !_clicked:
		return

	_clicked = false
	var mouse_pos = _clicked_at
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100.0
	var ray_cast = PhysicsRayQueryParameters3D.create(from, to)
	ray_cast.collide_with_areas = true

	var space_state = camera.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_cast)

	if result:
		var hit_position = result['position']
		target.calculate_nav(hit_position)
	else:
		print("No raycast hit")
