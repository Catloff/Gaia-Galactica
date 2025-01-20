@tool
extends Node3D

var collision_shape: CollisionShape3D
var static_body: StaticBody3D
var planet_mesh: MeshInstance3D
var height_data: Array = []
var biome_data: Array = []

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

func initialize(p_planet_mesh: MeshInstance3D):
	planet_mesh = p_planet_mesh
	print("[CollisionPlanet] Initialisiere mit PlanetMesh: ", planet_mesh.name)
	
	# Erstelle eine SphereShape3D für die Grundkollision
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 25.0  # PLANET_RADIUS
	collision_shape.shape = sphere_shape
	
	print("[CollisionPlanet] Kollisionsform erstellt mit Radius: ", sphere_shape.radius)

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
	
	for i in range(vertices.size()):
		var vertex_dir = vertices[i].normalized()
		var dist = dir.distance_to(vertex_dir)
		if dist < closest_dist:
			closest_dist = dist
			height = uvs[i].x  # Die Höheninformation ist in der X-Komponente der UV gespeichert
	
	print("[CollisionPlanet] Höhe an Position ", world_position, ": ", height)
	return height

func get_biome_at_position(world_position: Vector3) -> String:
	if not planet_mesh or not planet_mesh.mesh:
		print("[CollisionPlanet] FEHLER: PlanetMesh oder Mesh nicht gefunden")
		return "grass"  # Standardwert
	
	var height = get_height_at_position(world_position)
	
	# Biom basierend auf der Höhe bestimmen
	if height < 0.0:
		return "water"
	elif height > 0.6:
		return "mountain"
	else:
		return "grass"

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
	
	var biome_counts = {"water": 0, "grass": 0, "mountain": 0}
	
	for i in range(vertices.size()):
		var height = uvs[i].x  # Höheninformation aus UV
		var vertex_pos = vertices[i]
		height_data.append({"position": vertex_pos, "height": height})
		
		# Bestimme Biom basierend auf Höhe
		var biome = get_biome_for_height(height)
		biome_data.append(biome)
		biome_counts[biome] += 1
		
	print("Biom-Verteilung:")
	print("- Wasser: ", biome_counts["water"])
	print("- Gras: ", biome_counts["grass"])
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
