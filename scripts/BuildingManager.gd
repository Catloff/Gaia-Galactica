extends Node3D

var house_scene = preload("res://scenes/House.tscn")
var lumbermill_scene = preload("res://scenes/Lumbermill.tscn")
var preview_building: Node3D = null
var can_place = false
var build_mode = false
var current_building_type = "none"

@onready var resource_manager = get_node("../ResourceManager")
@onready var hud = get_node("../HUD")

func _ready():
	preview_building = house_scene.instantiate()
	preview_building.visible = false
	add_child(preview_building)
	hud.mode_changed.connect(_on_mode_changed)
	hud.building_selected.connect(_on_building_selected)

func _input(event):
	if not build_mode or current_building_type == "none":
		return
		
	if event is InputEventMouseMotion:
		update_preview_position(event.position)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_place and has_resources():
			place_building()

func update_preview_position(mouse_pos):
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Nur mit Ground kollidieren
	var result = space_state.intersect_ray(query)
	
	if result:
		preview_building.visible = true
		preview_building.position = result.position
		preview_building.position.y = 1.0  # Hälfte der Gebäudehöhe
		can_place = true
	else:
		preview_building.visible = false
		can_place = false

func has_resources() -> bool:
	var cost = get_current_building_cost()
	for resource in cost:
		if resource_manager.inventory[resource] < cost[resource]:
			return false
	return true

func place_building():
	var cost = get_current_building_cost()
	for resource in cost:
		resource_manager.inventory[resource] -= cost[resource]
	
	var new_building
	match current_building_type:
		"house":
			new_building = house_scene.instantiate()
		"lumbermill":
			new_building = lumbermill_scene.instantiate()
			
	new_building.position = preview_building.position
	get_parent().add_child(new_building)
	
	# Aktiviere Gebäude nach der Platzierung
	if current_building_type == "lumbermill" and new_building.has_method("activate"):
		new_building.activate()
		
	resource_manager.update_hud()

func _on_mode_changed(mode: String):
	build_mode = (mode == "build")
	if not build_mode:
		preview_building.visible = false
		current_building_type = "none"

func _on_building_selected(type: String):
	current_building_type = type
	remove_child(preview_building)
	
	match type:
		"house":
			preview_building = house_scene.instantiate()
		"lumbermill":
			preview_building = lumbermill_scene.instantiate()
	
	preview_building.visible = false
	add_child(preview_building)

func get_current_building_cost() -> Dictionary:
	match current_building_type:
		"house":
			return house_scene.instantiate().get_cost()
		"lumbermill":
			return lumbermill_scene.instantiate().get_cost()
		_:
			return {} 