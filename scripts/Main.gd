extends Node3D

# Preload häufig verwendeter Ressourcen
const RESOURCE_SCENE = preload("res://scenes/resources/Resource.tscn")
const LARGE_ROCK_SCENE = preload("res://scenes/resources/LargeRock.tscn")
const PLANTABLE_TREE_SCENE = preload("res://scenes/resources/PlantableTree.tscn")
const BUILDING_SCENES = {
	"Lumbermill": preload("res://scenes/buildings/Lumbermill.tscn"),
	"Quarry": preload("res://scenes/buildings/Quarry.tscn"),
	"Storage": preload("res://scenes/buildings/Storage.tscn"),
	"BerryGatherer": preload("res://scenes/buildings/BerryGatherer.tscn"),
	"Refinery": preload("res://scenes/buildings/Refinery.tscn")
}

const PLANET_RADIUS = 25.0  # Radius des Planeten
const MIN_CLUSTER_SIZE = 3
const MAX_CLUSTER_SIZE = 6
const MIN_DISTANCE_BETWEEN_CLUSTERS = 3.0
const RESOURCE_HEIGHT = 0.5
const RESOURCE_DENSITY = 0.005
const LARGE_ROCK_COUNT = 3
const LARGE_BUSH_COUNT = 3

var placed_positions = []
var collision_planet: Node3D
var loading_screen: Control

func _ready():
	show_loading_screen()
	initialize_game()

func show_loading_screen():
	loading_screen = preload("res://scenes/LoadingScreen.tscn").instantiate()
	add_child(loading_screen)
	loading_screen.loading_completed.connect(_on_loading_completed)

func initialize_game():
	# Warte zwei Frames für die Kamera-Initialisierung
	await get_tree().process_frame
	await get_tree().process_frame
	loading_screen.update_progress("Initialisiere Kamera...")
	
	# Initialisiere Kollisionsebene
	setup_collision_planet()
	loading_screen.update_progress("Erstelle Planetenoberfläche...")
	
	spawn_initial_base()
	loading_screen.update_progress("Platziere Basis...")
	
	spawn_resource_clusters()
	loading_screen.update_progress("Generiere Ressourcen...")
	
	spawn_large_rocks()
	spawn_large_bushes()
	loading_screen.update_progress("Platziere spezielle Ressourcen...")

func _on_loading_completed():
	print("Spiel vollständig geladen!")

func setup_collision_planet():
	var collision_scene = preload("res://scenes/CollisionPlanet.tscn")
	collision_planet = collision_scene.instantiate()
	add_child(collision_planet)
	
	# Korrigiere den Node-Pfad
	var planet_mesh = $Planet/PlanetMesh
	if not planet_mesh:
		push_error("PlanetMesh nicht gefunden! Aktueller Pfad: /Planet/PlanetGenerator/PlanetMesh")
		return
		
	print("PlanetMesh gefunden: ", planet_mesh.name)
	collision_planet.initialize(planet_mesh)

func spawn_large_bushes():
	var large_bush_scene = preload("res://scenes/resources/LargeBush.tscn")
	
	for _i in range(LARGE_BUSH_COUNT):
		var valid_pos = find_valid_position()
		if not valid_pos.is_valid:
			continue
			
		# Prüfe Biom
		var biome = collision_planet.get_biome_at_position(valid_pos.position)
		if biome != "grass":
			continue
			
		# Berechne tatsächliche Höhe
		var dir = valid_pos.position.normalized()
		var height = collision_planet.get_height_at_position(dir * PLANET_RADIUS)
		var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
		
		var bush = large_bush_scene.instantiate()
		add_child(bush)
		bush.position = dir * (terrain_height + 0.3)  # Büsche etwas über dem Terrain
		bush.look_at(Vector3.ZERO)
		bush.rotate_object_local(Vector3.RIGHT, PI/2)
		placed_positions.append(bush.position)

func spawn_large_rocks():
	var large_rock_scene = preload("res://scenes/resources/LargeRock.tscn")
	
	for _i in range(LARGE_ROCK_COUNT):
		var valid_pos = find_valid_position()
		if not valid_pos.is_valid:
			continue
			
		# Prüfe Biom
		var biome = collision_planet.get_biome_at_position(valid_pos.position)
		if biome != "mountain":
			continue
			
		# Berechne tatsächliche Höhe
		var dir = valid_pos.position.normalized()
		var height = collision_planet.get_height_at_position(dir * PLANET_RADIUS)
		var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
		
		var rock = large_rock_scene.instantiate()
		add_child(rock)
		rock.position = dir * (terrain_height + 0.5)  # Steine etwas über dem Terrain
		rock.look_at(Vector3.ZERO)
		rock.rotate_object_local(Vector3.RIGHT, PI/2)
		placed_positions.append(rock.position)

func spawn_resource_clusters():
	var resource_scene = preload("res://scenes/resources/Resource.tscn")
	
	# Berechne die Anzahl der Cluster basierend auf der Planetenoberfläche
	var surface_area = 4 * PI * PLANET_RADIUS * PLANET_RADIUS
	var base_clusters = int(surface_area * RESOURCE_DENSITY)
	var num_clusters = max(base_clusters + randi_range(-2, 2), 3)
	
	print("Erstelle %d Ressourcen-Cluster..." % num_clusters)
	
	# Garantiere mindestens einen Cluster pro Ressourcentyp in passendem Biom
	var guaranteed_clusters = {
		"grass": [0, 2],  # WOOD und FOOD in Gras
		"mountain": [1]    # STONE in Bergen
	}
	
	for biome in guaranteed_clusters:
		for resource_type in guaranteed_clusters[biome]:
			spawn_resource_cluster(resource_scene, resource_type, biome)
	
	# Restliche Cluster zufällig verteilen
	for _i in range(num_clusters - 3):
		var resource_type = randi() % 3
		spawn_resource_cluster(resource_scene, resource_type)

func spawn_resource_cluster(resource_scene: PackedScene, resource_type: int, target_biome: String = ""):
	var max_center_attempts = 10
	var center = null
	var biome = ""
	
	for _i in range(max_center_attempts):
		var test_pos = find_valid_position()
		if not test_pos.is_valid:
			continue
			
		biome = collision_planet.get_biome_at_position(test_pos.position)
		var is_valid_biome = false
		
		if target_biome != "":
			is_valid_biome = biome == target_biome
		else:
			match resource_type:
				0, 2:  # WOOD, FOOD
					is_valid_biome = biome == "grass"
				1:     # STONE
					is_valid_biome = biome == "mountain"
		
		if is_valid_biome:
			center = test_pos
			break
	
	if not center:
		return
		
	var cluster_size = randi_range(MIN_CLUSTER_SIZE, MAX_CLUSTER_SIZE)
	var placed_in_cluster = 0
	
	# Versuche Ressourcen im Cluster zu platzieren
	for _j in range(cluster_size * 3):  # Mehr Versuche für vollständige Cluster
		var angle = randf() * TAU
		var distance = randf_range(1.0, 3.0)
		
		var center_dir = center.position.normalized()
		var tangent = center_dir.cross(Vector3.UP).normalized()
		var bitangent = center_dir.cross(tangent)
		
		var offset = (tangent * cos(angle) + bitangent * sin(angle)) * distance
		var base_pos = (center_dir * PLANET_RADIUS + offset).normalized()
		
		# Hole die Höhe an dieser Position
		var height = collision_planet.get_height_at_position(base_pos * PLANET_RADIUS)
		var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)  # 20% Höhenvariation wie im Shader
		
		# Platziere die Ressource auf der Terrainhöhe plus einem kleinen Offset
		var resource_offset = 0.0
		match resource_type:
			0:  # WOOD - Bäume etwas tiefer für besseren Halt
				resource_offset = 0.2
			1:  # STONE - Steine etwas höher für bessere Sichtbarkeit
				resource_offset = 0.5
			2:  # FOOD - Beeren auf mittlerer Höhe
				resource_offset = 0.3
				
		var spawn_pos = base_pos * (terrain_height + resource_offset)
		
		if collision_planet.get_biome_at_position(spawn_pos) != biome:
			continue
			
		if not is_valid_position(spawn_pos):
			continue
			
		var resource = resource_scene.instantiate()
		resource.resource_type = resource_type
		add_child(resource)
		resource.position = spawn_pos
		resource.start_position = spawn_pos
		resource.look_at(Vector3.ZERO)
		resource.rotate_object_local(Vector3.RIGHT, PI/2)
		placed_positions.append(spawn_pos)
		placed_in_cluster += 1
		
		if placed_in_cluster >= cluster_size:
			break
	
	if placed_in_cluster > 0:
		print("Cluster mit %d Ressourcen in %s platziert" % [placed_in_cluster, biome])

class PositionResult:
	var position: Vector3
	var is_valid: bool
	
	func _init(pos: Vector3, valid: bool):
		position = pos
		is_valid = valid

func find_valid_position() -> PositionResult:
	var max_attempts = 20
	var current_attempt = 0
	
	while current_attempt < max_attempts:
		var phi = randf() * TAU
		var theta = acos(randf() * 2.0 - 1.0)
		
		var pos = Vector3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta)
		) * PLANET_RADIUS
		
		if is_valid_position(pos):
			return PositionResult.new(pos, true)
			
		current_attempt += 1
	
	return PositionResult.new(Vector3.ZERO, false)

func is_valid_position(pos: Vector3) -> bool:
	# Prüfe ob die Position im Wasser ist
	var biome = collision_planet.get_biome_at_position(pos)
	if biome == "water":
		return false
		
	# Prüfe Mindestabstand zu anderen Ressourcen
	for placed_pos in placed_positions:
		if pos.distance_to(placed_pos) < MIN_DISTANCE_BETWEEN_CLUSTERS:
			return false
	
	return true

func spawn_initial_base() -> void:
	print("Main: Starting base spawn process")
	
	# Get reference to BuildingManager
	var building_manager := get_node_or_null("BuildingManager")
	if not building_manager:
		print("ERROR: BuildingManager not found!")
		return
		
	# Finde eine gute Position für die Basis im Gras-Biom
	var spawn_dir = Vector3(0, 1, 0)  # Starte am "Nordpol"
	var spawn_pos = spawn_dir * PLANET_RADIUS
	var biome = collision_planet.get_biome_at_position(spawn_pos)
	
	# Wenn nicht im Gras, suche eine passende Position
	if biome != "grass":
		var found = false
		for i in range(36):  # Suche in 10-Grad-Schritten
			var angle = deg_to_rad(i * 10)
			spawn_dir = Vector3(sin(angle), cos(angle), 0)
			spawn_pos = spawn_dir * PLANET_RADIUS
			biome = collision_planet.get_biome_at_position(spawn_pos)
			if biome == "grass":
				found = true
				break
		
		if not found:
			print("ERROR: Keine geeignete Position für die Basis gefunden!")
			return
	
	# Berechne die tatsächliche Höhe
	var height = collision_planet.get_height_at_position(spawn_pos)
	var terrain_height = PLANET_RADIUS * (1.0 + height * 0.2)
	var spawn_position = spawn_dir * (terrain_height + 0.1)  # Leicht über dem Terrain
	
	print("Main: Attempting to spawn base at position ", spawn_position)
	var base_instance: Node3D = building_manager.spawn_base_on_planet(spawn_position)
	
	if base_instance:
		print("Main: Base spawned successfully")
		placed_positions.append(spawn_position)
	else:
		print("ERROR: Failed to spawn base!")
