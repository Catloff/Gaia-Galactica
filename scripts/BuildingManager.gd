extends Node3D

var lumbermill_scene = preload("res://scenes/Lumbermill.tscn")
var berry_gatherer_scene = preload("res://scenes/BerryGatherer.tscn")
var forester_scene = preload("res://scenes/Forester.tscn")
var plantable_tree_scene = preload("res://scenes/PlantableTree.tscn")
var smeltery_scene = preload("res://scenes/Smeltery.tscn")
var preview_building: Node3D = null
var can_place = false
var current_building_type = "none"
var demolish_mode = false

@onready var resource_manager = get_node("../ResourceManager")
@onready var hud = get_node("../HUD")
@onready var build_panel = get_node("../HUD/BuildPanel")
@onready var demolish_button = get_node("../HUD/BuildPanel/DemolishButton")

func _ready():
	hud.building_selected.connect(_on_building_selected)
	hud.demolish_mode_changed.connect(_on_demolish_mode_changed)

func _unhandled_input(event):
	if demolish_mode:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not is_mouse_over_ui():
				attempt_demolish(event.position)
				get_viewport().set_input_as_handled()
		return
		
	if current_building_type == "none":
		return
		
	if event is InputEventMouseMotion:
		update_preview_position(event.position)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_mouse_over_ui():
			return
			
		if can_place and has_resources():
			place_building()
			
	get_viewport().set_input_as_handled()

func attempt_demolish(mouse_pos: Vector2):
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0xFFFFFFFF  # Alle Kollisionsmasken aktivieren
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("get_cost"):
		print("Versuche Gebäude abzureißen: ", result.collider.name)
		# Gib einen Teil der Ressourcen zurück (50%)
		var cost = result.collider.get_cost()
		for resource in cost:
			var refund = cost[resource] / 2
			print("Erstatte %d %s zurück" % [refund, resource])
			resource_manager.add_resources({"type": resource, "amount": refund})
		
		# Entferne das Gebäude
		if result.collider.has_method("demolish"):
			result.collider.demolish()
		else:
			result.collider.queue_free()
		resource_manager.update_hud()
		print("Gebäude erfolgreich abgerissen!")

func _on_demolish_mode_changed(enabled: bool):
	demolish_mode = enabled
	if enabled:
		print("Abriss-Modus aktiviert")
		# Entferne Vorschau-Gebäude wenn vorhanden
		if preview_building:
			remove_child(preview_building)
			preview_building = null
		current_building_type = "none"
	else:
		print("Abriss-Modus deaktiviert")

func is_mouse_over_ui() -> bool:
	var mouse_pos = build_panel.get_viewport().get_mouse_position()
	var panel_rect = build_panel.get_global_rect()
	var demolish_rect = demolish_button.get_global_rect()
	return panel_rect.has_point(mouse_pos) or demolish_rect.has_point(mouse_pos)

func update_preview_position(mouse_pos):
	if is_mouse_over_ui():
		preview_building.visible = false
		can_place = false
		return
		
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Only collide with Ground
	var result = space_state.intersect_ray(query)
	
	if result:
		preview_building.visible = true
		preview_building.position = result.position
		preview_building.position.y = 1.0  # Half of building height
		can_place = true
	else:
		preview_building.visible = false
		can_place = false

func has_resources() -> bool:
	var cost = get_current_building_cost()
	return resource_manager.can_afford(cost)

func place_building():
	var cost = get_current_building_cost()
	if not resource_manager.pay_cost(cost):
		return
		
	var new_building
	match current_building_type:
		"lumbermill":
			new_building = lumbermill_scene.instantiate()
		"berry_gatherer":
			new_building = berry_gatherer_scene.instantiate()
		"forester":
			new_building = forester_scene.instantiate()
		"plant_tree":
			new_building = plantable_tree_scene.instantiate()
		"smeltery":
			new_building = smeltery_scene.instantiate()
			
	new_building.position = preview_building.position
	get_parent().add_child(new_building)
	
	if new_building.has_method("activate"):
		new_building.activate()
		
	resource_manager.update_hud()
	
	# Explicitly deselect the building after successful placement
	current_building_type = "none"
	if preview_building:
		remove_child(preview_building)
		preview_building = null
	hud.deselect_building()  # New method we'll add to HUD

func _on_building_selected(type: String):
	current_building_type = type
	
	if preview_building:
		remove_child(preview_building)
		preview_building = null
	
	if type != "none":
		match type:
			"lumbermill":
				preview_building = lumbermill_scene.instantiate()
			"berry_gatherer":
				preview_building = berry_gatherer_scene.instantiate()
			"forester":
				preview_building = forester_scene.instantiate()
			"plant_tree":
				preview_building = plantable_tree_scene.instantiate()
			"smeltery":
				preview_building = smeltery_scene.instantiate()
		
		if preview_building:
			preview_building.visible = false
			add_child(preview_building)

func get_current_building_cost() -> Dictionary:
	match current_building_type:
		"lumbermill":
			return lumbermill_scene.instantiate().get_cost()
		"berry_gatherer":
			return berry_gatherer_scene.instantiate().get_cost()
		"forester":
			return forester_scene.instantiate().get_cost()
		"plant_tree":
			return plantable_tree_scene.instantiate().get_cost()
		"smeltery":
			return smeltery_scene.instantiate().get_cost()
		_:
			return {}
