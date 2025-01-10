extends Node3D

@onready var camera: Camera3D = $Camera3D

var rotation_speed: float = 0.005
var zoom_speed: float = 0.1
var min_zoom: float = 10.0
var max_zoom: float = 100.0
var current_zoom: float = 45.0

func _ready() -> void:
	current_zoom = camera.transform.origin.length()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_zoom(event)
	elif event is InputEventMouseMotion:
		_handle_rotation(event)
	elif event is InputEventScreenDrag:
		_handle_touch_rotation(event)

func _handle_zoom(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-zoom_speed)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(zoom_speed)

func _handle_rotation(event: InputEventMouseMotion) -> void:
	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		_apply_camera_relative_rotation(event.relative)

func _handle_touch_rotation(event: InputEventScreenDrag) -> void:
	_apply_camera_relative_rotation(event.relative)

func _apply_camera_relative_rotation(relative: Vector2) -> void:
	# Erstelle Basis-Vektoren für die kamerarelative Rotation
	var camera_right := camera.global_transform.basis.x
	var camera_up := camera.global_transform.basis.y
	
	# Berechne die Rotationsachsen basierend auf der Kameraausrichtung
	var horizontal_axis := camera_up
	var vertical_axis := camera_right
	
	# Wende die Rotationen an
	rotate(horizontal_axis, -relative.x * rotation_speed)
	rotate(vertical_axis, -relative.y * rotation_speed)
	
	# Beschränke die vertikale Rotation um extreme Winkel zu vermeiden
	var up_dot := global_transform.basis.y.dot(Vector3.UP)
	if abs(up_dot) < 0.1:  # Verhindere Überkopf-Rotation
		rotate(vertical_axis, relative.y * rotation_speed)

func _zoom(zoom_factor: float) -> void:
	current_zoom = clamp(current_zoom + zoom_factor, min_zoom, max_zoom)
	var new_transform = camera.transform
	new_transform.origin = new_transform.origin.normalized() * current_zoom
	camera.transform = new_transform 
