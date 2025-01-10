extends Node3D

@onready var camera: Camera3D = $Camera3D

var rotation_speed: float = 0.005
var zoom_speed: float = 0.3
var min_zoom: float = 10.0
var max_zoom: float = 100.0
var current_zoom: float = 35.0

# Neue Variablen für die Rotationskontrolle
var current_rotation := Quaternion.IDENTITY
var up_vector := Vector3.UP
var initial_basis: Basis
var last_basis: Basis  # Speichert die letzte gültige Basis

func _ready() -> void:
	current_zoom = camera.transform.origin.length()
	
	# Explizite Konstruktion der initialen Basis
	var forward := Vector3(0, -0.5, 0.866025)  # Entspricht dem ursprünglichen Blickwinkel
	var up := Vector3(0, 0.866025, 0.5)        # Entspricht der ursprünglichen Up-Richtung
	var right := forward.cross(up).normalized()
	up = right.cross(forward).normalized()      # Reorthogonalisierung
	
	# Setze die Basis direkt
	global_transform.basis = Basis(right, up, -forward)
	last_basis = global_transform.basis  # Speichere die initiale Basis

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
	# Berechne die Rotationsachsen basierend auf der Kameraausrichtung
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	
	# Erstelle Quaternionen für beide Rotationen
	var horizontal_rotation := Quaternion(up, -relative.x * rotation_speed)
	var vertical_rotation := Quaternion(right, -relative.y * rotation_speed)
	
	# Wende zuerst die horizontale Rotation an
	var intermediate_basis := Basis(horizontal_rotation) * global_transform.basis
	
	# Dann die vertikale Rotation
	var new_basis := Basis(vertical_rotation) * intermediate_basis
	
	# Überprüfe den Winkel zur Up-Achse
	var new_up := new_basis.y
	var angle_to_up := new_up.angle_to(up_vector)
	
	# Verhindere zu extreme Rotationen (näher als 5 Grad an den Polen)
	if angle_to_up > 0.087 and angle_to_up < PI - 0.087:  # ~5 Grad in Radianten
		global_transform.basis = new_basis
		last_basis = new_basis  # Speichere die erfolgreiche Rotation
	else:
		# Bei Pol-Nähe: Nutze nur horizontale Rotation und behalte vertikale Position bei
		global_transform.basis = intermediate_basis
		last_basis = intermediate_basis

func _zoom(zoom_factor: float) -> void:
	current_zoom = clamp(current_zoom + zoom_factor, min_zoom, max_zoom)
	var new_transform = camera.transform
	new_transform.origin = new_transform.origin.normalized() * current_zoom
	camera.transform = new_transform 
