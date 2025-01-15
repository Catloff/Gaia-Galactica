extends "res://scripts/buildings/BaseBuilding.gd"

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 2.0  # Sekunden pro Ernte

var harvest_timer: float = 0.0

@onready var base_mesh = %Base
@onready var basket = %Basket

func _ready():
	super._ready()
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"food": 40},   # Level 1 -> 2
		{"food": 80}    # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)  # Hellbraun für den Sammler
	base_mesh.material_override = material
	
	var basket_material = StandardMaterial3D.new()
	basket_material.albedo_color = Color(0.6, 0.4, 0.2)  # Dunkelbraun für den Korb
	basket.material_override = basket_material

func _process(_delta):
	if not is_active:
		return
		
	# Leichte Bewegung des Korbs
	if basket:
		basket.position.y = 2.2 + sin(Time.get_ticks_msec() * 0.002) * 0.1

func _physics_process(delta):
	if not is_active:
		return
		
	harvest_timer += delta
	if harvest_timer >= get_production_rate():
		harvest_timer = 0.0
		harvest_nearby_food()

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
				resource_data["amount"] *= get_efficiency_multiplier()
				resource_manager.add_resources(resource_data)
				return  # Eine Ressource pro Tick

func get_production_rate() -> float:
	return HARVEST_RATE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr Beeren pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var brown_component = 0.8 + (current_level - 1) * 0.1  # Wird mit jedem Level heller
	base_material.albedo_color = Color(brown_component, 0.6, 0.4)
	base_mesh.material_override = base_material
	
	print("[BerryGatherer] Upgrade durchgeführt - Neues Level: %d" % current_level)

func get_building_radius() -> float:
	return HARVEST_RADIUS
