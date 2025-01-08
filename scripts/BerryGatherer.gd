extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 1.0  # Seconds per harvest

var harvest_timer: float = 0.0

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red for berries
	$MeshInstance3D.material_override = material

func get_base_cost() -> Dictionary:
	return {
		"food": 50
	}

func _process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		harvest_nearby_food()

func harvest_nearby_food():
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
			# Check resource type first
			if collider.get_resource_type() == "FOOD":
				var resource_data = collider.gather_resource()
				if resource_data != null:
					resource_manager.add_resources(resource_data)
					return  # Only harvest one resource per tick
