extends Node3D

const MAP_SIZE = 25.0  # Halbe Kartengröße
const MIN_CLUSTER_SIZE = 3
const MAX_CLUSTER_SIZE = 8
const MIN_DISTANCE_BETWEEN_CLUSTERS = 4.0
const RESOURCE_HEIGHT = 0.5
const RESOURCE_DENSITY = 0.01  # Cluster pro Quadrateinheit (0.01 = 1 Cluster pro 100 Einheiten)
const LARGE_ROCK_COUNT = 5  # Anzahl der großen Steine auf der Karte

var placed_positions = []

func _ready():
	setup_camera()
	spawn_resource_clusters()
	spawn_large_rocks()

func setup_camera():
	var camera = $Camera3D
	if camera:
		camera.position = Vector3(10, 10, 10)
		camera.look_at(Vector3.ZERO)

func spawn_large_rocks():
	var large_rock_scene = preload("res://scenes/LargeRock.tscn")
	
	for _i in range(LARGE_ROCK_COUNT):
		var valid_pos = find_valid_position()
		if not valid_pos.is_valid:
			continue
			
		var rock = large_rock_scene.instantiate()
		add_child(rock)
		rock.position = Vector3(valid_pos.position.x, 1.5, valid_pos.position.z)  # Höher platziert als normale Ressourcen
		placed_positions.append(valid_pos.position)

func spawn_resource_clusters():
	var resource_scene = preload("res://scenes/Resource.tscn")
	
	# Berechne die Anzahl der Cluster basierend auf der Kartengröße und Dichte
	var map_area = (MAP_SIZE * 2) * (MAP_SIZE * 2)  # Gesamtfläche der Karte
	var base_clusters = int(map_area * RESOURCE_DENSITY)  # Grundanzahl der Cluster
	var num_clusters = max(base_clusters + randi_range(-2, 2), 3)  # Mindestens 3 für jeden Ressourcentyp
	
	print("Spawning %d resource clusters on map area %d" % [num_clusters, map_area])
	
	# Sicherstellen, dass wir mindestens einen Cluster von jedem Typ haben
	var resource_types = [0, 1, 2]  # WOOD, STONE, FOOD
	resource_types.shuffle()  # Zufällige Reihenfolge
	
	# Zuerst einen Cluster von jedem Typ spawnen
	for resource_type in resource_types:
		spawn_resource_cluster(resource_scene, resource_type)
	
	# Dann die restlichen Cluster zufällig verteilen
	for _i in range(num_clusters - 3):
		var resource_type = randi() % 3
		spawn_resource_cluster(resource_scene, resource_type)

func spawn_resource_cluster(resource_scene: PackedScene, resource_type: int):
	# Zufällige Position für das Cluster-Zentrum
	var center = find_valid_position()
	if not center.is_valid:
		return
		
	# Größe des Clusters bestimmen
	var cluster_size = randi_range(MIN_CLUSTER_SIZE, MAX_CLUSTER_SIZE)
	
	# Ressourcen im Cluster platzieren
	for _j in range(cluster_size):
		# Zufällige Position im Umkreis des Zentrums
		var angle = randf() * TAU
		var distance = randf_range(1.0, 3.0)
		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)
		
		var pos = center.position + offset
		
		# Prüfen ob die Position gültig ist
		if not is_valid_position(pos):
			continue
			
		var resource = resource_scene.instantiate()
		resource.resource_type = resource_type
		add_child(resource)
		resource.position = Vector3(pos.x, RESOURCE_HEIGHT, pos.z)
		placed_positions.append(pos)

class PositionResult:
	var position: Vector3
	var is_valid: bool
	
	func _init(pos: Vector3, valid: bool):
		position = pos
		is_valid = valid

func find_valid_position() -> PositionResult:
	var max_attempts = 50
	var current_attempt = 0
	
	while current_attempt < max_attempts:
		var pos = Vector3(
			randf_range(-MAP_SIZE, MAP_SIZE),
			0,
			randf_range(-MAP_SIZE, MAP_SIZE)
		)
		
		if is_valid_position(pos):
			return PositionResult.new(pos, true)
			
		current_attempt += 1
	
	return PositionResult.new(Vector3.ZERO, false)

func is_valid_position(pos: Vector3) -> bool:
	# Prüfen ob Position innerhalb der Kartengrenzen
	if abs(pos.x) > MAP_SIZE or abs(pos.z) > MAP_SIZE:
		return false
	
	# Prüfen ob genügend Abstand zu anderen Ressourcen
	for existing_pos in placed_positions:
		if pos.distance_to(existing_pos) < 1.0:
			return false
			
	return true
