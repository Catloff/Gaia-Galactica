extends Node3D

var house_scene = preload("res://scenes/House.tscn")
var preview_house: Node3D = null
var can_place = false
var build_mode = false

@onready var resource_manager = get_node("../ResourceManager")
@onready var hud = get_node("../HUD")

func _ready():
	preview_house = house_scene.instantiate()
	preview_house.visible = false
	add_child(preview_house)
	hud.mode_changed.connect(_on_mode_changed)

func _input(event):
	if not build_mode:
		return
		
	if event is InputEventMouseMotion:
		update_preview_position(event.position)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_place and has_resources():
			place_house()

func update_preview_position(mouse_pos):
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Nur mit Ground kollidieren
	var result = space_state.intersect_ray(query)
	
	if result:
		preview_house.visible = true
		preview_house.position = result.position
		preview_house.position.y = 1.5  # Hälfte der Haushöhe
		can_place = true
	else:
		preview_house.visible = false
		can_place = false

func has_resources() -> bool:
	var cost = house_scene.instantiate().get_cost()
	for resource in cost:
		if resource_manager.inventory[resource] < cost[resource]:
			return false
	return true

func place_house():
	var cost = house_scene.instantiate().get_cost()
	for resource in cost:
		resource_manager.inventory[resource] -= cost[resource]
	
	var new_house = house_scene.instantiate()
	new_house.position = preview_house.position
	get_parent().add_child(new_house)
	resource_manager.update_hud()

func _on_mode_changed(mode: String):
	build_mode = (mode == "build")
	preview_house.visible = false 