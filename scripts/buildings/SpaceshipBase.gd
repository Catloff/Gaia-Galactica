extends BaseBuilding

class_name SpaceshipBase

var is_initialized: bool = false
var planet_instance = null
var debug_mesh_instance: MeshInstance3D = null

const BASE_RADIUS_BASE = 15.0  # Basis-Reichweite der Base
const BASE_RADIUS_PER_LEVEL = 5.0  # Zusätzliche Reichweite pro Level

func _ready():
	super._ready()
	add_to_group("base")
	setup_building()

func setup_building():
	# Base specific setup
	max_level = 3  # Maximum upgrade level for the base
	current_level = 1
	
	# Define upgrade costs for each level
	upgrade_costs = [
		{"metal": 100, "crystal": 50},  # Level 1 -> 2
		{"metal": 200, "crystal": 100, "energy": 50}  # Level 2 -> 3
	]
	
	# Set the base as active immediately
	is_active = true
	print("SpaceshipBase: Setup completed")

func get_efficiency_multiplier() -> float:
	# Base efficiency affects all buildings on the planet
	return 1.0 + (0.3 * (current_level - 1))  # 30% increase per level

func get_production_bonus() -> float:
	# Production bonus for all buildings
	return 0.1 * current_level  # 10% per level

# Override demolish to prevent base destruction
func demolish():
	print("Cannot demolish the base - it's essential for the colony!")
	return false

func initialize_on_planet(planet: Node3D) -> void:
	if not planet:
		print("ERROR: No planet node provided!")
		return
		
	planet_instance = planet
	is_initialized = true
	print("SpaceshipBase: Initialized on planet ", planet.name)

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)

func get_storage_radius() -> float:
	return BASE_RADIUS_BASE + (BASE_RADIUS_PER_LEVEL * (current_level - 1))

func get_building_radius() -> float:
	return get_storage_radius()  # Nutze Base-Radius für den Gebäude-Radius

func _on_upgrade():
	# Aktualisiere den Range-Indikator
	if range_indicator:
		var cylinder = range_indicator.mesh as CylinderMesh
		cylinder.top_radius = get_storage_radius()
		cylinder.bottom_radius = get_storage_radius()
	
	print("[SpaceshipBase] Upgrade durchgeführt - Neues Level: %d" % current_level)
	print("[SpaceshipBase] Neue Reichweite: %.1f" % get_storage_radius())

func setup_range_indicator():
	range_indicator = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = get_storage_radius()
	cylinder.bottom_radius = get_storage_radius()
	cylinder.height = 0.1
	range_indicator.mesh = cylinder
	
	# Material zur Laufzeit erstellen
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.8, 1, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.8, 1, 1)
	material.emission_energy_multiplier = 0.5
	
	range_indicator.material_override = material
	range_indicator.visible = false
	
	# Rotiere den Zylinder um 90 Grad um die X-Achse
	range_indicator.rotation_degrees.x = 90
	
	add_child(range_indicator)
