extends Node3D

enum BuildingCategory { RESOURCE, INFRASTRUCTURE, SPECIAL }

class BuildingDefinition:
	var scene: PackedScene
	var type: String
	var category: BuildingCategory
	var cost: Dictionary
	var display_name: String
	
	func _init(p_scene: PackedScene, p_type: String, p_category: BuildingCategory, p_cost: Dictionary, p_display_name: String):
		scene = p_scene
		type = p_type
		category = p_category
		cost = p_cost
		display_name = p_display_name
		
	func get_cost_text() -> String:
		var parts = []
		for resource in cost:
			parts.append("%d %s" % [cost[resource], resource])
		return "(%s)" % ", ".join(parts)

var buildings = {
	"lumbermill": BuildingDefinition.new(
		preload("res://scenes/buildings/Lumbermill.tscn"),
		"lumbermill",
		BuildingCategory.RESOURCE,
		{"wood": 60},
		"Sägewerk"
	),
	"berry_gatherer": BuildingDefinition.new(
		preload("res://scenes/buildings/BerryGatherer.tscn"),
		"berry_gatherer",
		BuildingCategory.RESOURCE,
		{"food": 50},
		"Beerensammler"
	),
	"forester": BuildingDefinition.new(
		preload("res://scenes/buildings/Forester.tscn"),
		"forester",
		BuildingCategory.INFRASTRUCTURE,
		{"wood": 80, "stone": 20},
		"Förster"
	),
	"plant_tree": BuildingDefinition.new(
		preload("res://scenes/buildings/PlantableTree.tscn"),
		"plant_tree",
		BuildingCategory.SPECIAL,
		{"wood": 10},
		"Baum pflanzen"
	),
	"smeltery": BuildingDefinition.new(
		preload("res://scenes/buildings/Smeltery.tscn"),
		"smeltery",
		BuildingCategory.INFRASTRUCTURE,
		{"wood": 80, "stone": 40},
		"Schmelze"
	),
	"quarry": BuildingDefinition.new(
		preload("res://scenes/buildings/Quarry.tscn"),
		"quarry",
		BuildingCategory.RESOURCE,
		{"wood": 40, "stone": 20},
		"Steinbruch"
	)
}

var preview_building: Node3D = null
var can_place = false
var current_building_type = "none"
var demolish_mode = false

var resource_manager
@onready var hud = $"../HUD"
@onready var build_panel = $"../HUD/BuildingHUD"
@onready var demolish_button = $"../HUD/BuildingHUD/DemolishButton"

signal buildings_updated

func _ready():
	resource_manager = $"/root/Main/ResourceManager"
	hud.building_selected.connect(_on_building_selected)
	hud.demolish_mode_changed.connect(_on_demolish_mode_changed)
	buildings_updated.emit()

func get_building_definition(type: String) -> BuildingDefinition:
	return buildings.get(type)

func get_buildings_by_category(category: BuildingCategory) -> Array:
	var result = []
	for type in buildings:
		var building = buildings[type]
		if building.category == category:
			result.append(building)
	return result

func can_afford_building(type: String) -> bool:
	var building = get_building_definition(type)
	if not building:
		return false
	return resource_manager.can_afford(building.cost)

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
			
		if can_place and can_afford_building(current_building_type):
			place_building()
			
	get_viewport().set_input_as_handled()

func attempt_demolish(mouse_pos: Vector2):
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0xFFFFFFFF
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("demolish"):
		print("Versuche Gebäude abzureißen: ", result.collider.name)
		
		# Find the building type from the collider's parent name
		var building_type = ""
		for type in buildings:
			if result.collider.get_parent().name.to_lower().begins_with(type):
				building_type = type
				break
				
		if building_type:
			# Get cost from building definition and refund 50%
			var building = get_building_definition(building_type)
			var cost = building.cost
			for resource in cost:
				var refund = cost[resource] / 2
				print("Erstatte %d %s zurück" % [refund, resource])
				resource_manager.add_resources({"type": resource, "amount": refund})
		
		# Remove the building
		result.collider.demolish()
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

func place_building():
	var building = get_building_definition(current_building_type)
	if not building:
		return
		
	var cost = building.cost
	if not resource_manager.pay_cost(cost):
		return
		
	var new_building = building.scene.instantiate()
	new_building.position = preview_building.position
	get_parent().add_child(new_building)
	
	if new_building.has_method("activate"):
		new_building.activate()
	
	# Explicitly deselect the building after successful placement
	current_building_type = "none"
	if preview_building:
		remove_child(preview_building)
		preview_building = null
	build_panel.deselect_building()  # New method we'll add to HUD

func _on_building_selected(type: String):
	current_building_type = type
	
	if preview_building:
		remove_child(preview_building)
		preview_building = null
	
	if type != "none":
		var building = get_building_definition(type)
		if building:
			preview_building = building.scene.instantiate()
			add_child(preview_building)
