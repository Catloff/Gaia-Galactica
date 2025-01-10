extends BaseBuilding

const PRODUCTION_RATE_BASE = 5.0  # Sekunden pro Produktion
const PRODUCTION_AMOUNT_BASE = 1  # Metall pro Produktion
const WOOD_COST = 2  # Holz pro Produktion
const STONE_COST = 1  # Stein pro Produktion

var production_timer: float = 0.0

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
	$Base.material_override = material
	
	var chimney_material = StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.3, 0.3, 0.3)  # Dunkelgrau
	$Chimney.material_override = chimney_material

func _process(delta):
	if not is_active:
		return
		
	production_timer += delta
	var production_rate = get_production_rate()
	
	if production_timer >= production_rate:
		production_timer = 0.0
		attempt_production()

func get_production_rate() -> float:
	match current_level:
		1: return PRODUCTION_RATE_BASE
		2: return PRODUCTION_RATE_BASE * 0.8  # 20% schneller
		3: return PRODUCTION_RATE_BASE * 0.6  # 40% schneller
	return PRODUCTION_RATE_BASE

func get_production_amount() -> int:
	match current_level:
		1: return PRODUCTION_AMOUNT_BASE
		2: return PRODUCTION_AMOUNT_BASE * 2  # Doppelte Produktion
		3: return PRODUCTION_AMOUNT_BASE * 3  # Dreifache Produktion
	return PRODUCTION_AMOUNT_BASE

func attempt_production():
	var cost = {
		"wood": WOOD_COST,
		"stone": STONE_COST
	}
	
	if resource_manager.can_afford(cost):
		if resource_manager.pay_cost(cost):
			var amount = get_production_amount()
			resource_manager.add_resources({"type": "metal", "amount": amount})

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var red_component = 0.4 + (current_level - 1) * 0.2  # Wird mit jedem Level rötlicher
	base_material.albedo_color = Color(red_component, 0.4, 0.4)
	$Base.material_override = base_material
	
	print("[Smeltery] Upgrade durchgeführt - Neues Level: %d" % current_level)
