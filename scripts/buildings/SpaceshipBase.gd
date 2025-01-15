extends BaseBuilding

class_name SpaceshipBase

var is_initialized: bool = false
var planet_instance = null
var debug_mesh_instance: MeshInstance3D = null

func _ready():
	super._ready()
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
