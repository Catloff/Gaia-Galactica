@tool
extends Node3D

var collision_shape: CollisionShape3D
var static_body: StaticBody3D
var planet_mesh: MeshInstance3D
var height_data: Array = []
var biome_data: Array = []
var noise: FastNoiseLite

func _ready():
	# Erstelle StaticBody3D wenn noch nicht vorhanden
	static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		add_child(static_body)
	
	# Setze Kollisionsmasken
	static_body.collision_layer = 2  # COLLISION_LAYER_GROUND
	static_body.collision_mask = 0   # Keine Kollision mit anderen Objekten
	
	# Erstelle CollisionShape3D wenn noch nicht vorhanden
	collision_shape = static_body.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)
	
	print("[CollisionPlanet] Kollisionsebene initialisiert")

func initialize(mesh: MeshInstance3D, world_seed: int = 0):
	planet_mesh = mesh
	
	# Initialisiere Noise mit dem Seed
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = world_seed
	noise.frequency = 0.4
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	
	print("[CollisionPlanet] Initialisiert mit Seed: ", world_seed)
	generate_collision_data()

func generate_collision_data():
	if not planet_mesh:
		push_error("[CollisionPlanet] Kein PlanetMesh gefunden!")
		return
		
	# Generiere Höhen- und Biomdaten basierend auf dem Noise
	height_data.clear()
	biome_data.clear()
	
	# Hier kommt deine bestehende Logik für die Höhen- und Biomgenerierung
	# ...

func get_height_at_position(world_position: Vector3) -> float:
	if not planet_mesh or not planet_mesh.mesh:
		print("[CollisionPlanet] FEHLER: PlanetMesh oder Mesh nicht gefunden")
		return 0.0
	
	var dir = world_position.normalized()
	
	# Hole die Mesh-Daten
	var mesh_data = planet_mesh.mesh.surface_get_arrays(0)
	if not mesh_data:
		print("[CollisionPlanet] FEHLER: Keine Mesh-Daten gefunden")
		return 0.0
		
	var vertices = mesh_data[Mesh.ARRAY_VERTEX]
	var uvs = mesh_data[Mesh.ARRAY_TEX_UV]
	
	if vertices.size() == 0 or uvs.size() == 0:
		print("[CollisionPlanet] FEHLER: Keine Vertices oder UVs gefunden")
		return 0.0
	
	# Finde den nächsten Vertex zur gegebenen Richtung
	var closest_dist = INF
	var height = 0.0
	var closest_vertex = Vector3.ZERO
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var vertex_dir = vertex.normalized()
		var dist = dir.distance_to(vertex_dir)
		if dist < closest_dist:
			closest_dist = dist
			height = uvs[i].x  # Die Höheninformation ist in der X-Komponente der UV gespeichert
			closest_vertex = vertex
	
	print("[CollisionPlanet] Nächster Vertex: ", closest_vertex)
	print("[CollisionPlanet] Höhe: ", height)
	return height

func get_biome_at_position(world_position: Vector3) -> String:
	if not planet_mesh or not planet_mesh.mesh:
		print("[CollisionPlanet] FEHLER: PlanetMesh oder Mesh nicht gefunden")
		return "grass"  # Standardwert
	
	var height = get_height_at_position(world_position)
	
	# Hole die Höhengrenzen aus dem Material
	var material = planet_mesh.material_override
	if not material:
		return "grass"
		
	var water_level = material.get_shader_parameter("water_level")
	var hill_level = material.get_shader_parameter("hill_level")
	var mountain_level = material.get_shader_parameter("mountain_level")
	
	# Biom basierend auf der Höhe bestimmen
	if height < water_level:
		return "water"
	elif height < hill_level:
		return "grass"
	elif height < mountain_level:
		return "hill"
	else:
		return "mountain"

func update_collision_shape():
	if not planet_mesh or not planet_mesh.mesh:
		push_error("Kein gültiges Mesh gefunden!")
		return
		
	var mesh_data = planet_mesh.mesh.surface_get_arrays(0)
	if not mesh_data:
		push_error("Keine Mesh-Daten gefunden!")
		return
		
	var vertices = mesh_data[Mesh.ARRAY_VERTEX]
	var uvs = mesh_data[Mesh.ARRAY_TEX_UV]
	
	print("Verarbeite Mesh mit ", vertices.size(), " Vertices")
	
	# Speichere Höhen- und Biomdaten
	height_data.clear()
	biome_data.clear()
	
	var biome_counts = {
		"water": 0,
		"grass": 0,
		"hill": 0,
		"mountain": 0
	}
	
	for i in range(vertices.size()):
		var height = uvs[i].x  # Höheninformation aus UV
		var vertex_pos = vertices[i]
		height_data.append({"position": vertex_pos, "height": height})
		
		# Bestimme Biom basierend auf Höhe
		var biome = get_biome_at_position(vertex_pos)
		biome_data.append(biome)
		biome_counts[biome] += 1
		
	print("Biom-Verteilung:")
	print("- Wasser: ", biome_counts["water"])
	print("- Gras: ", biome_counts["grass"])
	print("- Hügel: ", biome_counts["hill"])
	print("- Berge: ", biome_counts["mountain"])
	
	# Erstelle Kollisionsform
	var collision_mesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	
	collision_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(collision_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	collision_shape.shape = shape
	
	print("Kollisionsform erstellt")

func get_biome_for_height(height: float) -> String:
	if not planet_mesh or not planet_mesh.material_override:
		push_error("Material nicht gefunden!")
		return "grass"
		
	var water_level = planet_mesh.material_override.get_shader_parameter("water_level")
	var mountain_start = planet_mesh.material_override.get_shader_parameter("mountain_start")
	
	if height < water_level:
		return "water"
	elif height < mountain_start:
		return "grass"
	else:
		return "mountain" 
