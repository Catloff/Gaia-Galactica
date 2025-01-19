extends Node3D

enum BuildingCategory { RESOURCE, INFRASTRUCTURE, SPECIAL, BASE }

const PLANET_RADIUS = 25.0  # Muss mit dem Radius in Main.gd übereinstimmen

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
		preload("res://scenes/resources/PlantableTree.tscn"),
		"plant_tree",
		BuildingCategory.SPECIAL,
		{"wood": 10},
		"Baum pflanzen"
	),
	"refinery": BuildingDefinition.new(
		preload("res://scenes/buildings/Refinery.tscn"),
		"refinery",
		BuildingCategory.RESOURCE,
		{"metal": 50, "stone": 30},
		"Raffinerie"
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
	),
	"storage": BuildingDefinition.new(
		preload("res://scenes/buildings/Storage.tscn"),
		"storage",
		BuildingCategory.INFRASTRUCTURE,
		{"wood": 100, "stone": 50},
		"Lager"
	),
	"spaceship_base": BuildingDefinition.new(
		preload("res://scenes/buildings/SpaceshipBase.tscn"),
		"spaceship_base",
		BuildingCategory.BASE,
		{},  # No cost as it's automatically placed
		"Koloniestation"
	)
}

var preview_building: Node3D = null
var can_place = false
var current_building_type = "none"
var demolish_mode = false

var resource_manager
@onready var hud = $"../HUD"
@onready var build_panel = $"../HUD/BuildingHUD"
@onready var mobile_nav = $"../HUD/MobileNavigation"

signal buildings_updated
signal preview_building_changed(preview: BaseBuilding)

var is_touch_device = false
var pending_touch_position: Vector2 = Vector2.ZERO  # Neue Variable für ausstehende Touch-Position
var pending_demolish_position: Vector2 = Vector2.ZERO  # Neue Variable für ausstehende Abriss-Position

# Füge Kollisionsmasken als Konstanten hinzu
const COLLISION_LAYER_GROUND = 2
const COLLISION_LAYER_BUILDINGS = 4

var building_counters = {}

func _ready():
	resource_manager = $"/root/Main/ResourceManager"
	hud.building_selected.connect(_on_building_selected)
	hud.demolish_mode_changed.connect(_on_demolish_mode_changed)
	buildings_updated.emit()
	
	# Initialisiere Zähler für jeden Gebäudetyp
	for type in buildings:
		building_counters[type] = 0
	
	# Prüfe ob wir auf einem Touch-Gerät sind
	is_touch_device = DisplayServer.is_touchscreen_available()

func generate_building_name(building_type: String) -> String:
	building_counters[building_type] += 1
	return "%s_%d" % [building_type, building_counters[building_type]]

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

func _physics_process(_delta):
	# Verarbeite ausstehende Touch-Position
	if pending_touch_position != Vector2.ZERO:
		place_building_at_position(pending_touch_position)
		pending_touch_position = Vector2.ZERO
	
	# Verarbeite ausstehenden Abriss
	if pending_demolish_position != Vector2.ZERO and demolish_mode:
		print("[BuildingManager] Verarbeite Abriss an Position: ", pending_demolish_position)
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(pending_demolish_position)
		var to = from + camera.project_ray_normal(pending_demolish_position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		# Nur mit Gebäuden kollidieren
		query.collision_mask = COLLISION_LAYER_BUILDINGS
		var result = space_state.intersect_ray(query)
		
		if result:
			print("[BuildingManager] Kollision gefunden mit: ", result.collider.name)
			
			if result.collider is StaticBody3D:
				var target = result.collider
				# Wenn der Collider selbst keine demolish-Funktion hat, versuche es mit dem Parent
				if not target.has_method("demolish"):
					target = target.get_parent()
				
				if target:
					print("[BuildingManager] Ziel gefunden: ", target.name)
					print("[BuildingManager] Ziel Skript: ", target.get_script() if target.get_script() else "Kein Skript")
					
					if target.has_method("demolish"):
						print("[BuildingManager] Versuche Ziel abzureißen: ", target.name)
						
						# Prüfe ob es ein Gebäude ist
						var building_type = find_building_type(target.name)
						if building_type != "":
							print("[BuildingManager] Gebäudetyp erkannt: ", building_type)
							# Erstatte Ressourcen zurück
							var building_def = get_building_definition(building_type)
							if building_def:
								for resource_type in building_def.cost:
									var amount = building_def.cost[resource_type] / 2
									print("[BuildingManager] Erstatte ", amount, " ", resource_type, " zurück")
									resource_manager.add_resources({
										"type": resource_type,
										"amount": amount
									})
						
						target.demolish()
						print("[BuildingManager] Ziel erfolgreich abgerissen!")
					else:
						print("[BuildingManager] FEHLER: Ziel hat keine demolish()-Funktion")
				else:
					print("[BuildingManager] FEHLER: Kollider hat kein Parent-Node")
			else:
				print("[BuildingManager] FEHLER: Kollider ist kein StaticBody3D")
		else:
			print("[BuildingManager] Keine Kollision gefunden")
		
		pending_demolish_position = Vector2.ZERO

func _unhandled_input(event):
	# Konvertiere Touch zu Mausposition wenn nötig
	var mouse_pos = event.position if event is InputEventMouse else event.position if event is InputEventScreenTouch else Vector2.ZERO
	
	if demolish_mode:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
		   (event is InputEventScreenTouch and event.pressed):
			if not is_mouse_over_ui():
				pending_demolish_position = mouse_pos
				get_viewport().set_input_as_handled()
		return
		
	if current_building_type == "none":
		return
		
	# Nur für Maus-Geräte die Vorschau aktualisieren
	if not is_touch_device and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		update_preview_position(mouse_pos)
	
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		if is_mouse_over_ui():
			return
			
		if is_touch_device:
			# Für Touch-Geräte: Position speichern für nächsten _physics_process
			pending_touch_position = mouse_pos
		else:
			# Für Maus: Normale Platzierung mit Vorschau
			if can_place and can_afford_building(current_building_type):
				place_building()
			
	get_viewport().set_input_as_handled()

# Hilfsfunktion zum Finden des Gebäudetyps basierend auf einem Namen
func find_building_type(node_name: String) -> String:
	print("[BuildingManager] Suche Gebäudetyp für Namen: ", node_name)
	
	# Extrahiere den Basis-Namen ohne Nummer
	var base_name = node_name.split("_")[0] if "_" in node_name else node_name
	print("[BuildingManager] Extrahierter Basis-Name: ", base_name)
	
	# Deutsche Namen zu englischen Typen mappen
	match base_name:
		"sägewerk", "sagewerk", "lumbermill":
			return "lumbermill"
		"beerensammler", "berry_gatherer":
			return "berry_gatherer"
		"förster", "forster", "forester":
			return "forester"
		"raffinerie", "refinery":
			return "refinery"
		"schmelze", "smeltery":
			return "smeltery"
		"steinbruch", "quarry":
			return "quarry"
		"lager", "storage":
			return "storage"
		"koloniestation", "spaceship_base":
			return "spaceship_base"
	
	# Direkte Übereinstimmung mit building_types
	if buildings.has(base_name):
		return base_name
	
	print("[BuildingManager] WARNUNG: Kein Gebäudetyp gefunden für: ", node_name)
	return ""

func _on_demolish_mode_changed(enabled: bool):
	demolish_mode = enabled
	if enabled:
		print("Abriss-Modus aktiviert")
		# Breche den Bauvorgang korrekt ab
		cancel_building()
	else:
		print("Abriss-Modus deaktiviert")
		# Setze ausstehende Abriss-Position zurück
		pending_demolish_position = Vector2.ZERO

func is_mouse_over_ui() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	var panel_rect = build_panel.get_global_rect() if build_panel.visible else Rect2()
	var nav_rect = mobile_nav.get_global_rect()
	return panel_rect.has_point(mouse_pos) or nav_rect.has_point(mouse_pos)

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
		# Platziere das Gebäude auf der Planetenoberfläche
		var hit_pos = result.position
		preview_building.position = hit_pos
		
		# Richte das Gebäude zur Planetenmitte aus
		preview_building.look_at(Vector3.ZERO)
		preview_building.rotate_object_local(Vector3.RIGHT, PI/2)
		
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
	# Generiere einen eindeutigen Namen
	new_building.name = generate_building_name(building.type)
	# Setze die Position und Rotation BEVOR wir das Gebäude zur Szene hinzufügen
	new_building.position = preview_building.position
	new_building.rotation = preview_building.rotation
	get_parent().add_child(new_building)
	
	if new_building.has_method("activate"):
		new_building.activate()
	
	# Explicitly deselect the building after successful placement
	current_building_type = "none"
	if preview_building:
		remove_child(preview_building)
		preview_building = null
	build_panel.deselect_building()

func cancel_building():
	if preview_building:
		preview_building.queue_free()
		preview_building = null
	current_building_type = "none"
	can_place = false
	preview_building_changed.emit(null)
	build_panel.deselect_building()  # Deselektiere das Gebäude auch im BuildingHUD

func _on_building_selected(type: String):
	if type == "none":
		if preview_building:
			preview_building.queue_free()
			preview_building = null
		current_building_type = "none"
		can_place = false
		preview_building_changed.emit(null)
		return
		
	var building_def = get_building_definition(type)
	if not building_def:
		return
		
	if preview_building:
		preview_building.queue_free()
		
	preview_building = building_def.scene.instantiate()
	add_child(preview_building)
	current_building_type = type
	
	# Nur für echte Gebäude das Signal emittieren
	if type != "plant_tree":
		preview_building_changed.emit(preview_building)
	
	# Zeige den Range-Indikator für die Vorschau
	if preview_building.has_method("show_range_indicator"):
		preview_building.show_range_indicator(true)

func attempt_place_building(_spawn_position: Vector3) -> bool:
	if current_building_type == "spaceship_base":
		# Check if a base already exists
		for child in get_children():
			if child is SpaceshipBase:
				print("Only one base allowed per planet!")
				return false
	return true

func spawn_base_on_planet(spawn_position: Vector3) -> Node3D:
	print("BuildingManager: Attempting to spawn base at position ", spawn_position)
	var base_scene: PackedScene = preload("res://scenes/buildings/SpaceshipBase.tscn")
	var base_instance: Node3D = base_scene.instantiate()
	add_child(base_instance)
	
	# Set position
	base_instance.global_position = spawn_position
	
	# Calculate orientation
	var up_vector := spawn_position.normalized()  # Direction from planet center to base
	var forward_vector := Vector3.FORWARD
	if abs(up_vector.dot(Vector3.UP)) > 0.99:
		forward_vector = Vector3.FORWARD  # Use forward when up is aligned with global up
	else:
		forward_vector = Vector3.UP.cross(up_vector).normalized()
	var right_vector := up_vector.cross(forward_vector).normalized()
	
	# Create and apply the transform - make the base stand upright on the planet surface
	var transform_basis := Basis(right_vector, up_vector, -forward_vector).rotated(right_vector, PI/2)
	base_instance.global_transform.basis = transform_basis
	
	# Initialize the base
	base_instance.initialize_on_planet(get_parent())
	print("BuildingManager: Base spawned successfully")
	return base_instance

func place_building_at_position(pos: Vector2):
	if current_building_type == "none":
		return
		
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(pos)
	var to = from + camera.project_ray_normal(pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Only collide with Ground
	var result = space_state.intersect_ray(query)
	
	if result and can_afford_building(current_building_type):
		var building = get_building_definition(current_building_type)
		if building:
			var cost = building.cost
			if resource_manager.pay_cost(cost):
				var new_building = building.scene.instantiate()
				# Generiere einen eindeutigen Namen
				new_building.name = generate_building_name(building.type)
				# Erst zur Szene hinzufügen
				get_parent().add_child(new_building)
				# Dann Position und Rotation setzen
				new_building.position = result.position
				new_building.look_at_from_position(result.position, Vector3.ZERO, Vector3.UP)
				new_building.rotate_object_local(Vector3.RIGHT, PI/2)
				
				if new_building.has_method("activate"):
					new_building.activate()
				
				current_building_type = "none"
				build_panel.deselect_building()

func setup_collision():
	var static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		# Setze die Kollisionsmaske für Gebäude
		static_body.collision_layer = COLLISION_LAYER_BUILDINGS
		static_body.collision_mask = COLLISION_LAYER_BUILDINGS
		add_child(static_body)
		
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2, 2, 2)
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
	
	if not static_body.get_script():
		static_body.set_script(preload("res://scripts/buildings/BuildingBody.gd"))
		print("[BuildingManager] BuildingBody-Skript an StaticBody3D angehängt")
