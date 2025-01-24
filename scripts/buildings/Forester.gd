extends "res://scripts/buildings/BaseBuilding.gd"

const SCAN_RADIUS = 8.0
const PLANT_RATE = 10.0  # Sekunden zwischen Pflanzungen

var plant_timer: float = 0.0
var tree_stumps: Array = []  # Liste der Baumstümpfe

@onready var base_mesh = %Base
@onready var roof_mesh = %Roof

func _ready():
	super._ready()
	
	# Setze Upgrade-Kosten
	upgrade_costs = [
		{"wood": 80, "stone": 20},   # Level 1 -> 2
		{"wood": 160, "stone": 40}   # Level 2 -> 3
	]
	max_level = 3
	
	await scan_for_stumps()

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.3)  # Dunkelgrün für Förster
	base_mesh.material_override = material
	
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.3, 0.6, 0.4)  # Helleres Grün für das Dach
	roof_mesh.material_override = roof_material

func _physics_process(delta):
	if not is_active:
		return
		
	plant_timer += delta
	if plant_timer >= PLANT_RATE:
		plant_timer = 0.0
		attempt_regrow_tree()

func attempt_regrow_tree():
	# Aktualisiere die Liste der Stümpfe
	await scan_for_stumps()
	
	# Wenn wir keine Baumstümpfe haben, machen wir nichts
	if tree_stumps.is_empty():
		return
		

	# Wähle einen zufälligen Stumpf aus
	var stump = tree_stumps[randi() % tree_stumps.size()]
	
	# Lasse den Baum nachwachsen
	if stump.has_method("regrow_tree"):
		stump.regrow_tree()

func scan_for_stumps():
	tree_stumps.clear()
	print("[Forester] Starte Scan nach Baumstümpfen...")
	
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		print("[Forester] Fehler: Kein space_state verfügbar")
		return
		
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = SCAN_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	query_params.collision_mask = 4  # COLLISION_LAYER_BUILDINGS
	
	var results = space_state.intersect_shape(query_params)
	print("[Forester] Gefundene Kollisionen:", results.size())
	
	for result in results:
		var collider = result["collider"]
		print("[Forester] Prüfe Kollision mit:", collider)
		if collider.has_method("get_resource_type"):
			print("[Forester] - Hat get_resource_type Methode")
			if collider.get_resource_type() == "WOOD":
				print("[Forester] - Ist ein Holz-Ressource")
				if not collider.has_node("Crown"):
					print("[Forester] - Hat keine Krone - füge zu Stümpfen hinzu")
					tree_stumps.append(collider)
				else:
					print("[Forester] - Hat bereits eine Krone")
			else:
				print("[Forester] - Kein Holz:", collider.get_resource_type())
		else:
			print("[Forester] - Keine get_resource_type Methode")
	
	print("[Forester] Scan abgeschlossen - Gefundene Stümpfe:", tree_stumps.size())

func get_production_rate() -> float:
	return PLANT_RATE / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% schnelleres Wachstum pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func _on_upgrade():
	# Aktualisiere die Farbe basierend auf dem Level
	var base_material = StandardMaterial3D.new()
	var green_component = 0.5 + (current_level - 1) * 0.1  # Wird mit jedem Level heller grün
	base_material.albedo_color = Color(0.2, green_component, 0.3)
	base_mesh.material_override = base_material
	
	print("[Forester] Upgrade durchgeführt - Neues Level: %d" % current_level)

func get_building_radius() -> float:
	return SCAN_RADIUS

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)
