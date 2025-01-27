@tool
extends Node3D

enum BuildingCategory { RESOURCE, INFRASTRUCTURE, SPECIAL, BASE }

const PLANET_RADIUS = 25.0  # Muss mit dem Radius in Main.gd übereinstimmen
const SNAP_GRID_SIZE = 2.0  # Größe des Snapping-Grids in Einheiten

var preview_material_valid: StandardMaterial3D
var preview_material_invalid: StandardMaterial3D

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
signal preview_building_changed(preview: Node3D)

var is_touch_device = false
var pending_touch_position: Vector2 = Vector2.ZERO
var pending_demolish_position: Vector2 = Vector2.ZERO

# Füge Kollisionsmasken als Konstanten hinzu
const COLLISION_LAYER_GROUND = 2
const COLLISION_LAYER_BUILDINGS = 4

var building_counters = {}

var current_snap_position: Vector3 = Vector3.ZERO
var valid_snap_positions: Array[Vector3] = []

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO

func _ready():
	resource_manager = $"/root/Main/ResourceManager"
	hud.building_selected.connect(_on_building_selected)
	hud.demolish_mode_changed.connect(_on_demolish_mode_changed)
	buildings_updated.emit()
	
	for type in buildings:
		building_counters[type] = 0
	
	is_touch_device = DisplayServer.is_touchscreen_available()
	
	# Erstelle die Preview-Materialien
	preview_material_valid = StandardMaterial3D.new()
	preview_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_valid.albedo_color = Color(0, 1, 0, 0.5)
	preview_material_valid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_material_valid.no_depth_test = true
	preview_material_valid.render_priority = 100  # Stelle sicher, dass die Vorschau über allem anderen gerendert wird
	
	preview_material_invalid = StandardMaterial3D.new()
	preview_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_invalid.albedo_color = Color(1, 0, 0, 0.5)
	preview_material_invalid.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_material_invalid.no_depth_test = true
	preview_material_invalid.render_priority = 100

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
		
	# Aktualisiere die Vorschau bei jeder Mausbewegung oder Touch-Bewegung
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		update_preview_position(mouse_pos)
		get_viewport().set_input_as_handled()
	
	# Touch/Klick-Start für Drag & Drop
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and event.pressed):
		if is_mouse_over_ui():
			return
			
		is_dragging = true
		drag_start_position = mouse_pos
		get_viewport().set_input_as_handled()
	
	# Touch/Klick-Ende für Drag & Drop
	if (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or \
	   (event is InputEventScreenTouch and not event.pressed):
		if is_dragging:
			is_dragging = false
			# Nur platzieren wenn wir uns nicht zu weit bewegt haben
			if can_place and current_snap_position != Vector3.ZERO and preview_building and can_afford_building(current_building_type):
				place_building()
			get_viewport().set_input_as_handled()
	
	# Rechtsklick oder Escape zum Abbrechen
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT) or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		cancel_building()
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

func calculate_planet_aligned_basis(world_pos: Vector3) -> Basis:
	var up = world_pos.normalized()  # Richtung vom Planetenzentrum zum Gebäude
	var forward = Vector3.FORWARD
	
	# Wenn wir fast am Nordpol sind, verwende eine andere Referenzrichtung
	if abs(up.dot(Vector3.UP)) > 0.99:
		forward = -Vector3.FORWARD
	else:
		# Berechne eine Tangente zur Planetenoberfläche
		forward = Vector3.UP.cross(up).normalized()
	
	var right = up.cross(forward).normalized()
	forward = right.cross(up).normalized()  # Neuberechnung für eine perfekte Orthogonalität
	
	# Erstelle die Basis-Matrix
	return Basis(right, up, -forward)

func update_preview_position(mouse_pos: Vector2):
	if not preview_building:
		print("[BuildingManager] Keine Vorschau vorhanden")
		return
	
	print("[BuildingManager] Aktualisiere Vorschauposition")
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_LAYER_GROUND
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		var collision_planet = get_node("/root/Main/CollisionPlanet")
		if not collision_planet:
			print("[BuildingManager] CollisionPlanet nicht gefunden")
			return
		
		# Berechne die Position auf der Planetenoberfläche
		var dir = hit_pos.normalized()
		var height = collision_planet.get_height_at_position(dir * PLANET_RADIUS)
		var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
		var surface_pos = dir * terrain_height
		
		print("[BuildingManager] Oberflächenposition: ", surface_pos)
		print("[BuildingManager] Höhe: ", height)
		
		# Prüfe das Biom
		var biome = collision_planet.get_biome_at_position(surface_pos)
		print("[BuildingManager] Biom an Position: ", biome)
		
		# Berechne die Snapping-Position
		var snap_pos = find_nearest_snap_position(surface_pos)
		current_snap_position = snap_pos
		
		print("[BuildingManager] Snap-Position: ", snap_pos)
		
		# Setze die Position und Rotation der Vorschau
		preview_building.global_position = snap_pos
		preview_building.global_transform.basis = calculate_planet_aligned_basis(snap_pos)
		
		# Prüfe ob wir hier bauen können
		can_place = can_place_building(snap_pos)
		update_preview_material(can_place)
		
		print("[BuildingManager] Platzierung möglich: ", can_place)
	else:
		print("[BuildingManager] Kein Treffer mit dem Terrain gefunden")
		# Versuche eine alternative Methode zur Positionsbestimmung
		var planet_center = Vector3.ZERO
		var ray_dir = camera.project_ray_normal(mouse_pos)
		var closest_point = find_closest_point_on_sphere(from, ray_dir, planet_center, PLANET_RADIUS)
		
		if closest_point != Vector3.ZERO:
			print("[BuildingManager] Alternative Position gefunden: ", closest_point)
			var dir = closest_point.normalized()
			var collision_planet = get_node("/root/Main/CollisionPlanet")
			if collision_planet:
				var height = collision_planet.get_height_at_position(dir * PLANET_RADIUS)
				var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
				var surface_pos = dir * terrain_height
				
				# Berechne die Snapping-Position
				var snap_pos = find_nearest_snap_position(surface_pos)
				current_snap_position = snap_pos
				
				# Setze die Position und Rotation der Vorschau
				preview_building.global_position = snap_pos
				preview_building.global_transform.basis = calculate_planet_aligned_basis(snap_pos)
				
				# Prüfe ob wir hier bauen können
				can_place = can_place_building(snap_pos)
				update_preview_material(can_place)
				
				print("[BuildingManager] Alternative Platzierung möglich: ", can_place)

func find_closest_point_on_sphere(ray_origin: Vector3, ray_direction: Vector3, sphere_center: Vector3, sphere_radius: float) -> Vector3:
	# Berechne den Vektor vom Strahlenursprung zum Kugelmittelpunkt
	var oc = ray_origin - sphere_center
	
	# Berechne die Koeffizienten der quadratischen Gleichung
	var a = ray_direction.dot(ray_direction)
	var b = 2.0 * oc.dot(ray_direction)
	var c = oc.dot(oc) - sphere_radius * sphere_radius
	
	# Berechne die Diskriminante
	var discriminant = b * b - 4 * a * c
	
	if discriminant < 0:
		return Vector3.ZERO  # Kein Schnittpunkt
	
	# Berechne den näheren Schnittpunkt
	var t = (-b - sqrt(discriminant)) / (2.0 * a)
	if t < 0:
		t = (-b + sqrt(discriminant)) / (2.0 * a)  # Verwende den zweiten Schnittpunkt, wenn der erste hinter dem Strahl liegt
	
	if t < 0:
		return Vector3.ZERO  # Beide Schnittpunkte liegen hinter dem Strahl
	
	return ray_origin + ray_direction * t

func find_nearest_snap_position(pos: Vector3) -> Vector3:
	var dir = pos.normalized()
	var collision_planet = get_node("/root/Main/CollisionPlanet")
	
	# Berechne die Basis-Vektoren für das lokale Koordinatensystem
	var up = dir
	var right = up.cross(Vector3.UP).normalized()
	var forward = up.cross(right)
	
	# Berechne die lokalen Koordinaten
	var local_pos = Vector3(
		pos.dot(right),
		pos.dot(up),
		pos.dot(forward)
	)
	
	print("[BuildingManager] Lokale Position vor Snapping: ", local_pos)
	
	# Snappe zu einem Grid
	var snapped_local = Vector3(
		round(local_pos.x / SNAP_GRID_SIZE) * SNAP_GRID_SIZE,
		local_pos.y,
		round(local_pos.z / SNAP_GRID_SIZE) * SNAP_GRID_SIZE
	)
	
	print("[BuildingManager] Lokale Position nach Snapping: ", snapped_local)
	
	# Transformiere zurück in globale Koordinaten
	var snapped_pos = right * snapped_local.x + up * snapped_local.y + forward * snapped_local.z
	
	# Passe die Höhe an das Terrain an
	var height = collision_planet.get_height_at_position(snapped_pos.normalized() * PLANET_RADIUS)
	var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
	var final_pos = snapped_pos.normalized() * (terrain_height + 0.1)
	
	print("[BuildingManager] Finale Snap-Position: ", final_pos)
	return final_pos

func update_preview_material(is_valid_position: bool):
	if not preview_building:
		return
		
	# Setze das Material für alle MeshInstance3D-Nodes im Preview
	for child in preview_building.get_children():
		if child is MeshInstance3D:
			child.material_override = preview_material_valid if is_valid_position else preview_material_invalid

func place_building():
	print("[BuildingManager] Starte Gebäudeplatzierung")
	if not can_place:
		print("[BuildingManager] Platzierung nicht möglich: can_place ist false")
		return
	if not current_snap_position:
		print("[BuildingManager] Platzierung nicht möglich: keine Snap-Position")
		return
	if not preview_building:
		print("[BuildingManager] Platzierung nicht möglich: keine Vorschau")
		return
		
	var building = get_building_definition(current_building_type)
	if not building:
		print("[BuildingManager] Platzierung nicht möglich: keine Gebäudedefinition")
		return
		
	var cost = building.cost
	if not resource_manager.pay_cost(cost):
		print("[BuildingManager] Platzierung nicht möglich: nicht genug Ressourcen")
		return
		
	print("[BuildingManager] Erstelle neues Gebäude")
	var new_building = building.scene.instantiate()
	new_building.name = generate_building_name(building.type)
	
	# Füge das Gebäude zuerst zur Szene hinzu
	get_parent().add_child(new_building)
	
	# Setze die Position und Rotation
	new_building.global_position = current_snap_position
	new_building.global_transform.basis = calculate_planet_aligned_basis(current_snap_position)
	
	if new_building.has_method("activate"):
		new_building.activate()
	
	print("[BuildingManager] Räume auf")
	current_building_type = "none"
	if preview_building:
		preview_building.queue_free()
		preview_building = null
	build_panel.visible = false
	build_panel.deselect_building()
	
	buildings_updated.emit()
	print("[BuildingManager] Gebäude erfolgreich platziert")

func cancel_building():
	if preview_building:
		preview_building.queue_free()
		preview_building = null
	current_building_type = "none"
	can_place = false
	preview_building_changed.emit(null)
	# Deaktiviere die Signalverbindung temporär
	hud.building_selected.disconnect(_on_building_selected)
	build_panel.deselect_building()
	build_panel.visible = false
	# Reaktiviere die Signalverbindung
	hud.building_selected.connect(_on_building_selected)

func _on_building_selected(type: String):
	print("[BuildingManager] Gebäude ausgewählt: ", type)
	
	if type == "none":
		if preview_building:
			if preview_building.has_method("show_range_indicator"):
				preview_building.show_range_indicator(false)
			preview_building.queue_free()
			preview_building = null
			current_building_type = "none"
			can_place = false
			preview_building_changed.emit(null)
		return
	
	var building_def = get_building_definition(type)
	if not building_def:
		print("[BuildingManager] Gebäudedefinition nicht gefunden für: ", type)
		return
	
	print("[BuildingManager] Erstelle Vorschau für: ", type)
	if preview_building:
		if preview_building.has_method("show_range_indicator"):
			preview_building.show_range_indicator(false)
		preview_building.queue_free()
	
	preview_building = building_def.scene.instantiate()
	add_child(preview_building)
	current_building_type = type
	
	# Setze das Material für die Vorschau, aber NICHT für den Range-Indikator
	for child in preview_building.get_children():
		if child is MeshInstance3D and child.name != "RangeIndicator":
			var mesh = child as MeshInstance3D
			mesh.material_override = preview_material_valid
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	
	# Zeige den Range-Indikator sofort an
	if preview_building.has_method("show_range_indicator"):
		print("[BuildingManager] Aktiviere Range-Indikator für: ", preview_building.name)
		preview_building.show_range_indicator(true)
	
	preview_building_changed.emit(preview_building)
	
	# Aktualisiere die Position sofort
	var mouse_pos = get_viewport().get_mouse_position()
	update_preview_position(mouse_pos)
	print("[BuildingManager] Vorschau erstellt und positioniert")

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

func place_building_at_position(mouse_pos: Vector2) -> Node3D:
	if not can_afford_building(current_building_type):
		return null
		
	var camera = get_viewport().get_camera_3d()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_LAYER_GROUND
	var result = space_state.intersect_ray(query)
	
	if result:
		var pos = result.position
		
		var collision_planet = get_node("/root/Main/CollisionPlanet")
		if collision_planet:
			var dir = pos.normalized()
			var height = collision_planet.get_height_at_position(dir * PLANET_RADIUS)
			var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
			pos = dir * (terrain_height + 0.1)
		
		if can_place_building(pos):
			var building = create_building_instance(current_building_type, pos)
			if building:
				var building_def = get_building_definition(current_building_type)
				resource_manager.pay_cost(building_def.cost)
				building.name = generate_building_name(current_building_type)
				
				# Schließe das BuildingHUD nach erfolgreicher Platzierung
				build_panel.visible = false
				current_building_type = "none"
				if preview_building:
					remove_child(preview_building)
					preview_building = null
				build_panel.deselect_building()
				
				buildings_updated.emit()
				return building
	
	return null

func create_building_instance(building_type: String, world_position: Vector3) -> Node3D:
	var building_def = get_building_definition(building_type)
	if not building_def:
		return null
		
	var building = building_def.scene.instantiate()
	add_child(building)
	
	# Setze Position und Rotation
	building.global_position = world_position
	
	# Berechne Ausrichtung zum Planetenzentrum
	var up_vector = world_position.normalized()
	var forward = Vector3.FORWARD
	if abs(up_vector.dot(Vector3.UP)) > 0.99:
		forward = Vector3.FORWARD
	else:
		forward = Vector3.UP.cross(up_vector).normalized()
	var right = up_vector.cross(forward).normalized()
	
	# Erstelle und wende die Transformation an
	var transform_basis = Basis(right, up_vector, -forward).rotated(right, PI/2)
	building.global_transform.basis = transform_basis
	
	return building

func can_place_building(world_position: Vector3) -> bool:
	print("[BuildingManager] Prüfe Platzierungsmöglichkeit an Position: ", world_position)
	
	# Hole das Biom an der Position
	var collision_planet = get_node("/root/Main/CollisionPlanet")
	if not collision_planet:
		print("[BuildingManager] CollisionPlanet nicht gefunden")
		return false
		
	var biome = collision_planet.get_biome_at_position(world_position)
	print("[BuildingManager] Biom: ", biome)
	
	if biome == "water":
		print("[BuildingManager] Kann nicht im Wasser bauen")
		return false
	
	# Prüfe Mindestabstand zu anderen Gebäuden
	for building in get_tree().get_nodes_in_group("building"):
		var distance = world_position.distance_to(building.global_position)
		print("[BuildingManager] Abstand zu Gebäude ", building.name, ": ", distance)
		if distance < 3.0:
			print("[BuildingManager] Zu nah an anderem Gebäude")
			return false
	
	print("[BuildingManager] Position ist gültig für Platzierung")
	return true

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
