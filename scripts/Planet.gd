@tool
extends Node3D

@export var radius: float = 25.0
@export var noise_seed: int = 0:
	set(value):
		noise_seed = value
		_generate_noise()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	if Engine.is_editor_hint():
		_setup_planet()
	_generate_noise()

func _setup_planet():
	# Erstelle SphereMesh mit weniger Segmenten für Low-Poly Look
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	
	mesh_instance.mesh = sphere_mesh

func _generate_noise():
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.005
	noise.fractal_octaves = 4
	
	var noise_texture = NoiseTexture2D.new()
	noise_texture.width = 256
	noise_texture.height = 256
	noise_texture.noise = noise
	
	var material = mesh_instance.get_surface_override_material(0)
	if material:
		material.set_shader_parameter("noise_texture", noise_texture)
