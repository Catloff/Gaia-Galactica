extends "res://scripts/buildings/BaseBuilding.gd"

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 5  # Sekunden pro Ernte

var harvest_timer: float = 0.0

@onready var base_mesh = %Base
@onready var saw_mesh = %Saw

func _ready():
	super._ready()
	
	# Registriere als Produktionsgebäude
	add_to_group("buildings")
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"wood": 40, "stone": 20},   # Level 1 -> 2
		{"wood": 80, "stone": 40}    # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)  # Braun für Sägewerk
	base_mesh.material_override = material
	
	var saw_material = StandardMaterial3D.new()
	saw_material.albedo_color = Color(0.7, 0.7, 0.7)  # Silber für die Säge
	saw_mesh.material_override = saw_material

func _physics_process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= get_production_rate():
		harvest_timer = 0.0
		# Nur stoppen wenn lokales Lager voll UND kein Lager in Reichweite
		if not should_stop_production():
			harvest_nearby_wood()
		
	# Rotiere die Säge
	if saw_mesh:
		saw_mesh.rotate_z(delta * 2.0)

func harvest_nearby_wood():
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
			if collider.get_resource_type() == "WOOD":
				var resource_data = await collider.gather_resource()
				if resource_data != null:
					resource_data["amount"] *= get_efficiency_multiplier()
					add_resources("wood", resource_data["amount"])
					return  # Nur eine Ressource pro Tick ernten

func get_production_rate() -> float:
	return HARVEST_RATE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr Holz pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var brown_component = 0.6 + (current_level - 1) * 0.2  # Wird mit jedem Level dunkler braun
	base_material.albedo_color = Color(brown_component, 0.4, 0.2)
	base_mesh.material_override = base_material
	
	print("[Lumbermill] Upgrade durchgeführt - Neues Level: %d" % current_level)

func get_building_radius() -> float:
	return HARVEST_RADIUS

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)

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
			print("[Lumbermill] Ausrufezeichen angeklickt - Übertrage Ressourcen")
			transfer_resources_to_main_storage()
