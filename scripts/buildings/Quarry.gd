extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 5.0  # Auf 5 Sekunden angepasst für Konsistenz
const HARVEST_AMOUNT = 1.0  # Definiere explizite Erntemenge

var harvest_timer: float = 0.0

@onready var base_mesh = %Base
@onready var drill_mesh = %Drill

func _ready():
	super._ready()	
	# Registriere als Produktionsgebäude
	add_to_group("buildings")
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"stone": 40, "wood": 20},   # Level 1 -> 2
		{"stone": 80, "wood": 40}    # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5)  # Grau
	base_mesh.material_override = material
	
	var drill_material = StandardMaterial3D.new()
	drill_material.albedo_color = Color(0.3, 0.3, 0.3)  # Dunkelgrau
	drill_mesh.material_override = drill_material

func _process(delta):
	if not is_active:
		return
		
	# Rotiere den Bohrer
	if drill_mesh:
		drill_mesh.rotate_y(delta * 1.5)

func _physics_process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= get_production_rate():
		harvest_timer = 0.0
		# Nur stoppen wenn lokales Lager voll UND kein Lager in Reichweite
		if not should_stop_production():
			harvest_nearby_stone()

func harvest_nearby_stone():
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
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
					resource_data["amount"] = HARVEST_AMOUNT * get_efficiency_multiplier()
					add_resources("stone", resource_data["amount"])
					return  # Nur eine Ressource pro Tick ernten

func get_production_rate() -> float:
	return HARVEST_RATE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr Stein pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func get_building_radius() -> float:
	return HARVEST_RADIUS

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var gray_component = 0.5 + (current_level - 1) * 0.1  # Wird mit jedem Level heller
	base_material.albedo_color = Color(gray_component, gray_component, gray_component)
	base_mesh.material_override = base_material
	
	print("[Quarry] Upgrade durchgeführt - Neues Level: %d" % current_level)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.get_parent() == storage_warning_mesh:
			print("[Quarry] Ausrufezeichen angeklickt - Übertrage Ressourcen")
			transfer_resources_to_main_storage()
