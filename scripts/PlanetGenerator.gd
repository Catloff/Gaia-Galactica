@tool
extends MeshInstance3D

var triangles = []
var verticies = []

@export_range(0, 6) var subdivisions: int = 4:
	set(value):
		subdivisions = value
		generate_planet()

@export_range(0.1, 10.0) var roughness: float = 0.8:
	set(value):
		roughness = value
		generate_planet()

@export_range(10.0, 100.0) var radius: float = 25.0:
	set(value):
		radius = value
		generate_planet()

@export var noise: FastNoiseLite:
	set(value):
		noise = value
		generate_planet()

@export var update_noise: bool = false:
	set(value):
		generate_planet()

# Biome Parameter
@export_range(0.0, 1.0) var water_level: float = 0.25:
	set(value):
		water_level = value
		_update_material()

@export_range(0.0, 1.0) var hill_level: float = 0.5:
	set(value):
		hill_level = value
		_update_material()

@export_range(0.0, 1.0) var mountain_level: float = 0.75:
	set(value):
		mountain_level = value
		_update_material()

@export var water_color: Color = Color(0.1, 0.3, 0.5):
	set(value):
		water_color = value
		_update_material()

@export var grass_color: Color = Color(0.2, 0.5, 0.2):
	set(value):
		grass_color = value
		_update_material()

@export var hill_color: Color = Color(0.3, 0.4, 0.2):
	set(value):
		hill_color = value
		_update_material()

@export var mountain_color: Color = Color(0.4, 0.3, 0.2):
	set(value):
		mountain_color = value
		_update_material()

var current_seed: int = 0

func _ready() -> void:
	initialize_noise()
	
	# Material initial erstellen
	material_override = ShaderMaterial.new()
	material_override.shader = preload("res://shaders/planet.gdshader")
	
	generate_planet()

func initialize_noise() -> void:
	if not noise:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.seed = current_seed
		noise.frequency = 0.4  # Reduzierte Frequenz für größere Flächen
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 3  # Reduzierte Oktaven für klarere Strukturen
		noise.fractal_lacunarity = 2.0
		noise.fractal_gain = 0.5

func set_seed(new_seed: int) -> void:
	current_seed = new_seed
	if noise:
		noise.seed = current_seed
	else:
		initialize_noise()
	print("[PlanetGenerator] Seed gesetzt auf: ", current_seed)

func generate_planet() -> void:
	if not noise:
		initialize_noise()
	
	triangles.clear()
	verticies.clear()
	mesh = null
	
	generate_icosphere()
	subdivide_icosphere()
	generate_mesh()
	_update_material()

func generate_mesh() -> void:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Finde Min/Max Noise-Werte für Normalisierung
	var min_noise = 1.0
	var max_noise = -1.0
	var noise_values = []
	
	# Erste Schleife: Noise-Werte sammeln
	for triangle in triangles:
		for vertex_idx in triangle.verticies:
			var vertex = verticies[vertex_idx]
			var noise_val = 0.0
			
			if noise:
				# Berechne Noise relativ zum Zentrum
				var pos = vertex.normalized()
				noise_val = noise.get_noise_3d(
					pos.x * roughness * 10.0,
					pos.y * roughness * 10.0,
					pos.z * roughness * 10.0
				)
				
				# Quantisiere den Noise-Wert in vier Stufen
				if noise_val < -0.5:
					noise_val = 0.0  # Wasser
				elif noise_val < 0.0:
					noise_val = 0.33  # Gras
				elif noise_val < 0.5:
					noise_val = 0.66  # Hügel
				else:
					noise_val = 1.0  # Berg
			
			noise_values.push_back(noise_val)
			min_noise = min(min_noise, noise_val)
			max_noise = max(max_noise, noise_val)
	
	# Zweite Schleife: Vertices erstellen mit normalisierten Höhen
	var noise_idx = 0
	for triangle in triangles:
		var vertices_pos = []
		var heights = []
		
		for vertex_idx in triangle.verticies:
			var vertex = verticies[vertex_idx].normalized()
			var noise_val = noise_values[noise_idx]
			noise_idx += 1
			
			# Normalisiere Noise-Wert auf 0-1 Bereich
			var normalized_height = (noise_val - min_noise) / (max_noise - min_noise)
			var displacement = 1.0 + normalized_height * 0.2  # 20% Höhenvariation
			
			vertices_pos.push_back(vertex * radius * displacement)
			heights.push_back(normalized_height)
		
		# Berechne Normal und füge Vertices hinzu
		var normal = (vertices_pos[1] - vertices_pos[0]).cross(vertices_pos[2] - vertices_pos[0]).normalized()
		
		for i in range(vertices_pos.size() - 1, -1, -1):
			surface_tool.set_normal(normal)
			surface_tool.set_uv(Vector2(heights[i], 0.0))
			surface_tool.add_vertex(vertices_pos[i])
	
	surface_tool.index()
	mesh = surface_tool.commit()

func _update_material() -> void:
	if material_override and material_override is ShaderMaterial:
		material_override.set_shader_parameter("noise_texture", noise)
		material_override.set_shader_parameter("water_level", water_level)
		material_override.set_shader_parameter("hill_level", hill_level)
		material_override.set_shader_parameter("mountain_level", mountain_level)
		material_override.set_shader_parameter("water", water_color)
		material_override.set_shader_parameter("grass", grass_color)
		material_override.set_shader_parameter("hill", hill_color)
		material_override.set_shader_parameter("mountain", mountain_color)

func generate_icosphere() -> void:
	var t = (1.0 + sqrt(5.0)) / 2.0
	
	verticies.push_back(Vector3(-1, t, 0).normalized())
	verticies.push_back(Vector3(1, t, 0).normalized())
	verticies.push_back(Vector3(-1, -t, 0).normalized())
	verticies.push_back(Vector3(1, -t, 0).normalized())
	verticies.push_back(Vector3(0, -1, t).normalized())
	verticies.push_back(Vector3(0, 1, t).normalized())
	verticies.push_back(Vector3(0, -1, -t).normalized())
	verticies.push_back(Vector3(0, 1, -t).normalized())
	verticies.push_back(Vector3(t, 0, -1).normalized())
	verticies.push_back(Vector3(t, 0, 1).normalized())
	verticies.push_back(Vector3(-t, 0, -1).normalized())
	verticies.push_back(Vector3(-t, 0, 1).normalized())
	
	triangles.push_back(Triangle.new(0, 11, 5))
	triangles.push_back(Triangle.new(0, 5, 1))
	triangles.push_back(Triangle.new(0, 1, 7))
	triangles.push_back(Triangle.new(0, 7, 10))
	triangles.push_back(Triangle.new(0, 10, 11))
	triangles.push_back(Triangle.new(1, 5, 9))
	triangles.push_back(Triangle.new(5, 11, 4))
	triangles.push_back(Triangle.new(11, 10, 2))
	triangles.push_back(Triangle.new(10, 7, 6))
	triangles.push_back(Triangle.new(7, 1, 8))
	triangles.push_back(Triangle.new(3, 9, 4))
	triangles.push_back(Triangle.new(3, 4, 2))
	triangles.push_back(Triangle.new(3, 2, 6))
	triangles.push_back(Triangle.new(3, 6, 8))
	triangles.push_back(Triangle.new(3, 8, 9))
	triangles.push_back(Triangle.new(4, 9, 5))
	triangles.push_back(Triangle.new(2, 4, 11))
	triangles.push_back(Triangle.new(6, 2, 10))
	triangles.push_back(Triangle.new(8, 6, 7))
	triangles.push_back(Triangle.new(9, 8, 1))

func subdivide_icosphere() -> void:
	var cache = {}
	
	for i in subdivisions:
		var new_triangle = []
		
		for triangle in triangles:
			var a = triangle.verticies[0]
			var b = triangle.verticies[1]
			var c = triangle.verticies[2]
			
			var ab = get_mid(cache, a, b)
			var bc = get_mid(cache, b, c)
			var ca = get_mid(cache, c, a)
			
			new_triangle.push_back(Triangle.new(a, ab, ca))
			new_triangle.push_back(Triangle.new(b, bc, ab))
			new_triangle.push_back(Triangle.new(c, ca, bc))
			new_triangle.push_back(Triangle.new(ab, bc, ca))
		
		triangles = new_triangle

func get_mid(cache : Dictionary, a: int, b: int) -> int:
	var smaller = min(a, b)
	var greater = max(a, b)
	var key = (smaller << 16) + greater
	
	if cache.has(key):
		return cache.get(key)
	
	var p1 = verticies[a]
	var p2 = verticies[b]
	var middle = lerp(p1, p2, 0.5).normalized()
	var ret = verticies.size()
	verticies.push_back(middle)
	cache[key] = ret
	return ret

class Triangle:
	var verticies = []
	func _init(a, b, c):
		verticies.push_back(a)
		verticies.push_back(b)
		verticies.push_back(c) 
