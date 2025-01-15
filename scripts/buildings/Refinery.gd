extends BaseBuilding

const FOOD_COST = 2
const FUEL_OUTPUT = 1
const BASE_PROCESS_TIME = 5.0

var process_timer = 0.0

@onready var base_mesh = %Base
@onready var chimney_mesh = %Chimney

func _ready():
	super._ready()
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"metal": 10, "stone": 20},   # Level 1 -> 2
		{"metal": 20, "stone": 40}    # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.7)  # Blue-ish for refinery
	base_mesh.material_override = material
	
	var chimney_material = StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.3, 0.3, 0.3)  # Dunkelgrau für den Schornstein
	chimney_mesh.material_override = chimney_material

func _physics_process(delta):
	if not is_active:
		return
		
	process_timer += delta
	if process_timer >= get_process_time():
		process_timer = 0.0
		try_produce_fuel()

func try_produce_fuel():
	var costs = {"food": FOOD_COST}
	if not resource_manager.can_afford(costs):
		print("[Refinery] Nicht genug Nahrung für Produktion")
		return
		
	if resource_manager.pay_cost(costs):
		var amount = FUEL_OUTPUT * get_efficiency_multiplier()
		resource_manager.add_resources({"type": "fuel", "amount": amount})
		print("[Refinery] Produziere %.1f Treibstoff" % amount)
		
		# Aktualisiere die Farbe des Schornsteins basierend auf der Produktion
		var chimney_material = StandardMaterial3D.new()
		chimney_material.albedo_color = Color(0.2, 0.6, 0.8)  # Blau für aktive Produktion
		chimney_material.emission_enabled = true
		chimney_material.emission = Color(0.2, 0.6, 0.8)
		chimney_material.emission_energy_multiplier = 0.5
		chimney_mesh.material_override = chimney_material

func get_process_time() -> float:
	return BASE_PROCESS_TIME / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr Output pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var blue_component = 0.6 + (current_level - 1) * 0.2  # Wird mit jedem Level blauer
	base_material.albedo_color = Color(0.4, blue_component, 0.7)
	base_mesh.material_override = base_material
	
	print("[Refinery] Upgrade durchgeführt - Neues Level: %d" % current_level)

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)
