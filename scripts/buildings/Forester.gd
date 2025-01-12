extends BaseBuilding

const SCAN_RADIUS = 8.0
const PLANT_RATE = 3.0  # Sekunden zwischen Pflanzungen

var plant_timer: float = 0.0
var tree_stumps: Array = []  # Liste der Baumstümpfe

@onready var base_mesh = %Base
@onready var roof_mesh = %Roof

func _setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.3)  # Dunkelgrün für Förster
	base_mesh.material_override = material
	
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.3, 0.6, 0.4)  # Helleres Grün für das Dach
	roof_mesh.material_override = roof_material

func _ready():
	super._ready()
	await scan_for_stumps()

func _process(_delta):
	if not is_active:
		return
		
	plant_timer += _delta
	if plant_timer >= PLANT_RATE:
		plant_timer = 0.0
		attempt_regrow_tree()

func attempt_regrow_tree():
	# Aktualisiere die Liste der Stümpfe
	await scan_for_stumps()
	
	# Wenn wir keine Baumstümpfe haben, machen wir nichts
	if tree_stumps.is_empty():
		print("[Förster] Keine Baumstümpfe gefunden")
		return
		
	print("[Förster] %d Baumstümpfe gefunden" % tree_stumps.size())
	
	# Wähle einen zufälligen Stumpf aus
	var stump = tree_stumps[randi() % tree_stumps.size()]
	
	# Lasse den Baum nachwachsen
	if stump.has_method("regrow_tree"):
		print("[Förster] Lasse Baum nachwachsen")
		stump.regrow_tree()
	else:
		print("[Förster] Stumpf hat keine regrow_tree Methode!")

func scan_for_stumps():
	tree_stumps.clear()
	
	var space_state = get_world_3d().direct_space_state
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = SCAN_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	query_params.collision_mask = 1  # Stelle sicher, dass wir die richtige Kollisionsmaske haben
	
	var results = space_state.intersect_shape(query_params)
	print("[Förster] Scanne nach Stümpfen... %d Objekte gefunden" % results.size())
	
	for result in results:
		var collider = result["collider"]
		if collider.has_method("get_resource_type"):
			print("[Förster] Ressource gefunden: %s, Hat Krone: %s" % [collider.get_resource_type(), str(collider.has_node("Crown"))])
			if collider.get_resource_type() == "WOOD" and not collider.has_node("Crown"):
				tree_stumps.append(collider)
				print("[Förster] Baumstumpf zur Liste hinzugefügt")
