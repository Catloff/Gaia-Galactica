extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 3.0  # Sekunden pro Ernte

var harvest_timer: float = 0.0

@onready var base_mesh = %Base
@onready var drill_mesh = %Drill

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5)  # Grau
	base_mesh.material_override = material
	
	var drill_material = StandardMaterial3D.new()
	drill_material.albedo_color = Color(0.3, 0.3, 0.3)  # Dunkelgrau
	drill_mesh.material_override = drill_material

func get_base_cost() -> Dictionary:
	return {
		"wood": 40,
		"stone": 20
	}

func _process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		harvest_nearby_stone()
		
	# Rotiere den Bohrer
	if drill_mesh:
		drill_mesh.rotate_y(delta * 1.5)

func harvest_nearby_stone():
	var space_state = get_world_3d().direct_space_state
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = HARVEST_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	
	var results = space_state.intersect_shape(query_params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("gather_resource") and collider.has_method("get_resource_type"):
			# Prüfe erst den Ressourcentyp
			if collider.get_resource_type() == "STONE":
				var resource_data = await collider.gather_resource()
				if resource_data != null:
					resource_manager.add_resources(resource_data)
					return  # Nur eine Ressource pro Tick ernten 
