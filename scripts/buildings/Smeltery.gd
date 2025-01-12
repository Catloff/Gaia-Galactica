extends BaseBuilding

const PRODUCTION_RATE_BASE = 5.0  # Sekunden pro Produktion
const PRODUCTION_AMOUNT_BASE = 1  # Metall pro Produktion
const WOOD_COST = 2  # Holz pro Produktion
const STONE_COST = 1  # Stein pro Produktion

var production_timer: float = 0.0

@onready var base_mesh = %Base
@onready var chimney_mesh = %Chimney

func _ready():
	super._ready()
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"metal": 5, "stone": 20},   # Level 1 -> 2
		{"metal": 10, "stone": 40}   # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.4)  # Grau
	base_mesh.material_override = material
	
	var chimney_material = StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.3, 0.3, 0.3)  # Dunkelgrau
	chimney_mesh.material_override = chimney_material

func _process(delta):
	if not is_active:
		return
		
	production_timer += delta
	var production_rate = get_production_rate()
	
	if production_timer >= production_rate:
		production_timer = 0.0
		attempt_production()

func attempt_production():
	var costs = {
		"wood": WOOD_COST,
		"stone": STONE_COST
	}
	
	if resource_manager.pay_cost(costs):
		resource_manager.add_resources({
			"type": "metal",
			"amount": PRODUCTION_AMOUNT_BASE * get_efficiency_multiplier()
		})

func get_production_rate() -> float:
	return PRODUCTION_RATE_BASE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * current_level)  # 25% mehr Output pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * current_level)  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var red_component = 0.4 + (current_level - 1) * 0.2  # Wird mit jedem Level rötlicher
	base_material.albedo_color = Color(red_component, 0.4, 0.4)
	base_mesh.material_override = base_material
	
	print("[Smeltery] Upgrade durchgeführt - Neues Level: %d" % current_level)
