extends Node3D

const PLANET_RADIUS = 25.0  # Radius des Planeten
const MIN_CLUSTER_SIZE = 3
const MAX_CLUSTER_SIZE = 8
const MIN_DISTANCE_BETWEEN_CLUSTERS = 4.0
const RESOURCE_HEIGHT = 0.5
const RESOURCE_DENSITY = 0.01
const LARGE_ROCK_COUNT = 5
const LARGE_BUSH_COUNT = 4

var placed_positions = []

func _ready():
	spawn_resource_clusters()
	spawn_large_rocks()
	spawn_large_bushes()

func spawn_large_bushes():
	var large_bush_scene = preload("res://scenes/resources/LargeBush.tscn")
	
	for _i in range(LARGE_BUSH_COUNT):
		var valid_pos = find_valid_position()
		if not valid_pos.is_valid:
			continue
			
		var bush = large_bush_scene.instantiate()
		add_child(bush)
		var spawn_pos = valid_pos.position.normalized() * PLANET_RADIUS
		bush.position = spawn_pos
		bush.look_at(Vector3.ZERO)  # Ausrichtung zur Planetenmitte
		bush.rotate_object_local(Vector3.RIGHT, PI/2)  # Korrektur der Rotation
		placed_positions.append(spawn_pos)

func spawn_large_rocks():
	var large_rock_scene = preload("res://scenes/resources/LargeRock.tscn")
	
	for _i in range(LARGE_ROCK_COUNT):
		var valid_pos = find_valid_position()
		if not valid_pos.is_valid:
			continue
			
		var rock = large_rock_scene.instantiate()
		add_child(rock)
		var spawn_pos = valid_pos.position.normalized() * PLANET_RADIUS
		rock.position = spawn_pos
		rock.look_at(Vector3.ZERO)  # Ausrichtung zur Planetenmitte
		rock.rotate_object_local(Vector3.RIGHT, PI/2)  # Korrektur der Rotation
		placed_positions.append(spawn_pos)

func spawn_resource_clusters():
	var resource_scene = preload("res://scenes/resources/Resource.tscn")
	
	# Berechne die Anzahl der Cluster basierend auf der Planetenoberfläche
	var surface_area = 4 * PI * PLANET_RADIUS * PLANET_RADIUS
	var base_clusters = int(surface_area * RESOURCE_DENSITY)
	var num_clusters = max(base_clusters + randi_range(-2, 2), 3)
	
	print("Spawning %d resource clusters on planet surface area %d" % [num_clusters, surface_area])
	
	var resource_types = [0, 1, 2]  # WOOD, STONE, FOOD
	resource_types.shuffle()
	
	for resource_type in resource_types:
		spawn_resource_cluster(resource_scene, resource_type)
	
	for _i in range(num_clusters - 3):
		var resource_type = randi() % 3
		spawn_resource_cluster(resource_scene, resource_type)

func spawn_resource_cluster(resource_scene: PackedScene, resource_type: int):
	var center = find_valid_position()
	if not center.is_valid:
		return
		
	var cluster_size = randi_range(MIN_CLUSTER_SIZE, MAX_CLUSTER_SIZE)
	
	for _j in range(cluster_size):
		# Zufällige Position auf der Kugeloberfläche im Umkreis des Zentrums
		var angle = randf() * TAU
		var distance = randf_range(1.0, 3.0)
		
		# Berechne die Position auf der Kugeloberfläche
		var center_dir = center.position.normalized()
		var tangent = center_dir.cross(Vector3.UP).normalized()
		var bitangent = center_dir.cross(tangent)
		
		var offset = (tangent * cos(angle) + bitangent * sin(angle)) * distance
		var spawn_pos = (center_dir * PLANET_RADIUS + offset).normalized() * (PLANET_RADIUS + 0.5)
		
		if not is_valid_position(spawn_pos):
			continue
			
		var resource = resource_scene.instantiate()
		resource.resource_type = resource_type
		add_child(resource)
		resource.position = spawn_pos
		resource.start_position = spawn_pos
		resource.look_at(Vector3.ZERO)  # Ausrichtung zur Planetenmitte
		resource.rotate_object_local(Vector3.RIGHT, PI/2)  # Korrektur der Rotation
		placed_positions.append(spawn_pos)

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
		# Generiere zufällige Position auf der Kugeloberfläche
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
	for placed_pos in placed_positions:
		if pos.distance_to(placed_pos) < MIN_DISTANCE_BETWEEN_CLUSTERS:
			return false
	return true
