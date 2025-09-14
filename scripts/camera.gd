extends Camera2D

# from https://github.com/cng6sk/Godot-TopDown-Camera2d/blob/main/addons/TopDownCamera2D/top_down_camera_2d.gd with modifications

@onready var camera : Camera2D = self

#region Exported
@export_group("Key Controls")

@export var pan_input : String = "drag"
@export var zoom_in_input : String = "zoomIn"
@export var zoom_out_input : String = "zoomOut"
@export var zoom_follow_cursor : bool = true

@export var pan_up_input: String = "pan_up"
@export var pan_down_input: String = "pan_down"
@export var pan_left_input: String = "pan_left"
@export var pan_right_input: String = "pan_right"

@export_range(100, 2000, 10) var pan_speed: float = 1000.0
@export_range(1, 20, 0.01) var max_zoom_level : float = 1.5
@export_range(0.01, 1, 0.01) var min_zoom_level : float = 0.5
@export_range(0.01, 0.2, 0.01) var zoom_factor : float = 0.08

@export_group("Edge Scrolling")

@export var edge_scroll_enabled: bool = true
@export_range(1, 600, 1) var edge_scroll_margin: float = 100.0
@export_range(0, 1000, 10) var edge_scroll_speed: float = 400.0

@export_group("Smoothness")

@export_range(0, 0.99, 0.01) var pan_smoothness : float = 0.6:
	set(new_val):
		pan_smoothness = new_val
		if not Engine.is_editor_hint():
			pan_smoothness = pow(new_val, smooth_factor)
	get:
		return pan_smoothness

@export_range(0, 0.99, 0.01) var zoom_smoothness : float = 0.6:
	set(new_val):
		zoom_smoothness = new_val
		if not Engine.is_editor_hint():
			zoom_smoothness = pow(new_val, smooth_factor)
	get:
		return zoom_smoothness 

const smooth_factor : float = 0.25

#endregion


#region Init
@onready var target_zoom := camera.zoom
@onready var target_position := camera.position

const base_fps : float = 120.0

var prev_mouse_pos : Vector2
var zoom_mouse_pos : Vector2

func _ready() -> void:
	pan_smoothness = pan_smoothness
	zoom_smoothness = zoom_smoothness
#endregion


func _process(delta: float) -> void:
	#print("_process")
	var pan_interpolation := pow(pan_smoothness, base_fps * delta)
	var zoom_interpolation := pow(zoom_smoothness, base_fps * delta)
	
	# edge scrolling function
	if edge_scroll_enabled && !Input.is_action_pressed(pan_input):
		var mouse_pos := get_viewport().get_mouse_position()
		var viewport_size := get_viewport_rect().size
		var screen_center := viewport_size * 0.5
		var scroll_direction := Vector2.ZERO
		
		var is_outside := (
			mouse_pos.x < 0 or
			mouse_pos.x > viewport_size.x or
			mouse_pos.y < 0 or
			mouse_pos.y > viewport_size.y
		)
		
		# is_in_edge
		var is_in_edge_area := (
			mouse_pos.x < edge_scroll_margin or
			mouse_pos.x > viewport_size.x - edge_scroll_margin or
			mouse_pos.y < edge_scroll_margin or
			mouse_pos.y > viewport_size.y - edge_scroll_margin
		)
		# Update
		if is_in_edge_area && !is_outside:
			scroll_direction = (mouse_pos - screen_center).normalized()
			target_position += scroll_direction * edge_scroll_speed * delta

	# Keyboard Movement
	var keyboard_pan_direction := Vector2.ZERO
	if Input.is_action_pressed(pan_left_input):
		keyboard_pan_direction.x -= 5.0
	if Input.is_action_pressed(pan_right_input):
		keyboard_pan_direction.x += 5.0
	if Input.is_action_pressed(pan_up_input):
		keyboard_pan_direction.y -= 5.0
	if Input.is_action_pressed(pan_down_input):
		keyboard_pan_direction.y += 5.0

	if keyboard_pan_direction != Vector2.ZERO:
		keyboard_pan_direction = keyboard_pan_direction.normalized()
		target_position += keyboard_pan_direction * pan_speed * delta

	var pre_mouseZoom_posGlobal := get_canvas_transform().affine_inverse().basis_xform(zoom_mouse_pos)
	camera.zoom = camera.zoom * zoom_interpolation + (1.0 - zoom_interpolation) * target_zoom
	var post_mouseZoom_posGlobal := get_canvas_transform().affine_inverse().basis_xform(zoom_mouse_pos)
	var zoom_offset := (pre_mouseZoom_posGlobal - post_mouseZoom_posGlobal) if zoom_follow_cursor else Vector2.ZERO

	target_position += zoom_offset
	camera.position = pan_interpolation * camera.position  + zoom_offset + target_position * (1.0 - pan_interpolation)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouse and not event is InputEventAction:
		return

	var curr_mouse_pos := get_local_mouse_position()
	
	if Input.is_action_just_pressed(zoom_in_input):
		target_zoom *= 1.0 / (1.0 - zoom_factor)
		zoom_mouse_pos = get_viewport().get_mouse_position()

	if Input.is_action_just_pressed(zoom_out_input):
		target_zoom *= (1.0 - zoom_factor)
		zoom_mouse_pos = get_viewport().get_mouse_position()

	if Input.is_action_pressed(pan_input):
		#print(target_position)
		target_position += (prev_mouse_pos - curr_mouse_pos)

	target_zoom = target_zoom.clamp(Vector2.ONE * min_zoom_level, Vector2.ONE * max_zoom_level)
	prev_mouse_pos = curr_mouse_pos
