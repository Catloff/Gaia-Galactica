extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 1.0  # Sekunden pro Ernte

var harvest_timer: float = 0.0

func setup_building():
	
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)  # Braun
	$MeshInstance3D.material_override = material

func get_base_cost() -> Dictionary:
	return {
		"wood": 60
	}

func _process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		harvest_nearby_wood()

func harvest_nearby_wood():
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
			if collider.get_resource_type() == "WOOD":
				var resource_data = collider.gather_resource()
				if resource_data != null:
					resource_manager.add_resources(resource_data)
					return  # Nur eine Ressource pro Tick ernten
