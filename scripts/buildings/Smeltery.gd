extends "res://scripts/buildings/BaseBuilding.gd"

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

func _physics_process(delta):
	if not is_active:
		return
		
	production_timer += delta
	var production_rate = get_production_rate()
	
	if production_timer >= production_rate:
		production_timer = 0.0
		attempt_production()

func attempt_production():
	# Prüfe ob wir genug Ressourcen haben
	var required_resources = {"wood": WOOD_COST, "stone": STONE_COST}
	if not resource_manager.can_afford(required_resources):
		print("[Smeltery] Nicht genug Ressourcen für Produktion")
		return
		
	# Verbrauche die Ressourcen
	resource_manager.pay_cost(required_resources)
	
	# Produziere Metall
	var amount = PRODUCTION_AMOUNT_BASE * get_efficiency_multiplier()
	resource_manager.add_resources({"type": "metal", "amount": amount})
	print("[Smeltery] Produziere %.1f Metall" % amount)
	
	# Aktualisiere die Farbe des Schornsteins basierend auf der Produktion
	var chimney_material = StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.8, 0.4, 0.2)  # Orange-rot für aktive Produktion
	chimney_material.emission_enabled = true
	chimney_material.emission = Color(0.8, 0.4, 0.2)
	chimney_material.emission_energy_multiplier = 0.5
	chimney_mesh.material_override = chimney_material

func get_production_rate() -> float:
	return PRODUCTION_RATE_BASE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr Metall pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var gray_component = 0.4 + (current_level - 1) * 0.1  # Wird mit jedem Level heller
	base_material.albedo_color = Color(gray_component, gray_component, gray_component)
	base_mesh.material_override = base_material
	
	print("[Smeltery] Upgrade durchgeführt - Neues Level: %d" % current_level)
