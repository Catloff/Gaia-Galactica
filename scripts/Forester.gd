extends BaseBuilding

const PLANT_RADIUS = 8.0  # Größerer Radius als Lumbermill
const PLANT_RATE = 3.0  # Sekunden pro Pflanzversuch
const TREE_HEIGHT = 0.5  # Aus Main.gd RESOURCE_HEIGHT

var plant_timer: float = 0.0
var tree_positions = []  # Speichert Positionen wo Bäume waren

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 0.3)  # Grün für Förster
	$MeshInstance3D.material_override = material

func get_base_cost() -> Dictionary:
	return {
		"wood": 80,
		"stone": 20
	}

func _process(delta):
	if not is_active:
		return
		
	plant_timer += delta
	if plant_timer >= PLANT_RATE:
		plant_timer = 0.0
		attempt_tree_planting()

func activate():
	super.activate()
	print("Förster aktiviert!")
	scan_for_trees()  # Scannt initial nach Bäumen im Radius

func scan_for_trees():
	var space_state = get_world_3d().direct_space_state
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = PLANT_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	
	var results = space_state.intersect_shape(query_params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("get_resource_type"):
			if collider.get_resource_type() == "WOOD":
				# Speichere die Position des Baums
				tree_positions.append(collider.global_position)
				# Verbinde das Signal für diesen Baum, wenn es noch nicht verbunden ist
				if not collider.resource_removed.is_connected(_on_tree_removed):
					collider.resource_removed.connect(_on_tree_removed)
					# Nur ein Förster funktioniert in dem Radius

func attempt_tree_planting():
	if tree_positions.is_empty():
		return
		
	# Wähle eine zufällige bekannte Baumposition
	var random_index = randi() % tree_positions.size()
	var plant_pos = tree_positions[random_index]
	
	# Prüfe ob an der Position bereits etwas ist
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		plant_pos + Vector3.UP * 10,
		plant_pos + Vector3.DOWN * 10
	)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.name == "Ground":
		# Platz ist frei, pflanze einen neuen Baum
		var resource_scene = load("res://scenes/Resource.tscn")
		var new_tree = resource_scene.instantiate()
		new_tree.resource_type = 0  # WOOD type
		get_parent().add_child(new_tree)
		new_tree.global_position = Vector3(plant_pos.x, TREE_HEIGHT, plant_pos.z)
		new_tree.resource_removed.connect(_on_tree_removed)  # Verbinde auch das Signal des neuen Baums
		print("Förster pflanzt einen neuen Baum!")
		# Entferne die Position aus der Liste, da dort jetzt ein Baum steht
		tree_positions.remove_at(random_index)

func _on_tree_removed(pos: Vector3, type: String):
	if type == "WOOD" and pos.distance_to(global_position) <= PLANT_RADIUS:
		if not tree_positions.has(pos):
			tree_positions.append(pos)
			print("Förster merkt sich Position eines gefällten Baums")
