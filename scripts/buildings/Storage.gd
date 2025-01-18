extends "res://scripts/buildings/BaseBuilding.gd"

const STORAGE_CAPACITY_BASE = 200  # Basis-Lagerkapazität
const STORAGE_CAPACITY_PER_LEVEL = 100  # Zusätzliche Kapazität pro Level
const STORAGE_RADIUS_BASE = 10.0  # Basis-Reichweite
const STORAGE_RADIUS_PER_LEVEL = 2.0  # Zusätzliche Reichweite pro Level

@onready var base_mesh = %Base
@onready var top_mesh = %Top

func _ready():
	super._ready()
	
	# Registriere das Lagergebäude in der Gruppe
	add_to_group("storage_buildings")
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"wood": 100, "stone": 50},   # Level 1 -> 2
		{"wood": 200, "stone": 100}   # Level 2 -> 3
	]
	max_level = 3

func setup_building():
	# Setze Gebäudefarben
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.6, 0.4, 0.2)  # Braun für die Basis
	base_mesh.material_override = base_material
	
	var top_material = StandardMaterial3D.new()
	top_material.albedo_color = Color(0.7, 0.5, 0.3)  # Helleres Braun für den oberen Teil
	top_mesh.material_override = top_material

func get_storage_capacity() -> int:
	return STORAGE_CAPACITY_BASE + (STORAGE_CAPACITY_PER_LEVEL * (current_level - 1))

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% mehr Effizienz pro Level

func activate():
	if is_active:
		print("[Storage] Warnung: Lager wurde bereits aktiviert!")
		return
		
	print("[Storage] Aktiviere Lager - Erhöhe Kapazität um: ", get_storage_capacity())
	is_active = true
	# Erhöhe die maximale Lagerkapazität
	resource_manager.increase_storage_capacity(get_storage_capacity())

func deactivate():
	if not is_active:
		print("[Storage] Warnung: Lager war nicht aktiv!")
		return
		
	print("[Storage] Deaktiviere Lager - Verringere Kapazität um: ", get_storage_capacity())
	is_active = false
	# Verringere die maximale Lagerkapazität
	resource_manager.decrease_storage_capacity(get_storage_capacity())

func demolish():
	deactivate()
	super.demolish() 

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs) 

func get_storage_radius() -> float:
	return STORAGE_RADIUS_BASE + (STORAGE_RADIUS_PER_LEVEL * (current_level - 1))

func get_building_radius() -> float:
	return get_storage_radius()  # Nutze Storage-Radius für den Gebäude-Radius 

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var brown_component = 0.6 + (current_level - 1) * 0.1  # Wird mit jedem Level heller
	base_material.albedo_color = Color(brown_component, 0.4, 0.2)
	base_mesh.material_override = base_material
	
	# Aktualisiere den Range-Indikator
	if range_indicator:
		var cylinder = range_indicator.mesh as CylinderMesh
		cylinder.top_radius = get_storage_radius()
		cylinder.bottom_radius = get_storage_radius()
	
	print("[Storage] Upgrade durchgeführt - Neues Level: %d" % current_level)
	print("[Storage] Neue Reichweite: %.1f" % get_storage_radius()) 
