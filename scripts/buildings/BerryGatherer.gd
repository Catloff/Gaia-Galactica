extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 1.0  # Sekunden pro Ernte

var harvest_timer: float = 0.0

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Rot
	$Visual/Base.material_override = material
	
	var basket_material = StandardMaterial3D.new()
	basket_material.albedo_color = Color(0.6, 0.3, 0.1)  # Braun
	$Visual/Basket.material_override = basket_material

func _process(_delta):
	if not is_active:
		return
		
	harvest_timer += _delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		await harvest_nearby_food()
		
	# Leichte Bewegung des Korbs
	if $Visual/Basket:
		$Visual/Basket.position.y = 2.2 + sin(Time.get_ticks_msec() * 0.002) * 0.1

func harvest_nearby_food() -> void:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = HARVEST_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	query_params.collision_mask = 1  # Stelle sicher dass die Kollisionsmaske gesetzt ist
	
	var results = space_state.intersect_shape(query_params)
	if results.is_empty():
		return  # Keine Ressourcen in Reichweite
		
	for result in results:
		if not "collider" in result:
			continue
			
		var collider = result["collider"]
		if not is_instance_valid(collider):
			continue  # Überspringe ungültige Collider
			
		if not (collider.has_method("gather_resource") and collider.has_method("get_resource_type")):
			continue
			
		# Prüfe erst den Ressourcentyp
		if collider.get_resource_type() == "FOOD":
			var resource_data = await collider.gather_resource()
			if resource_data != null:
				resource_manager.add_resources(resource_data)
				return  # Eine Ressource pro Tick
