extends BaseBuilding

const SCAN_RADIUS = 8.0
const PLANT_RATE = 3.0  # Sekunden zwischen Pflanzungen
const MIN_TREE_DISTANCE = 2.0  # Mindestabstand zwischen Bäumen

var plant_timer: float = 0.0
var tree_positions: Array = []
var stump_positions: Array = []

func _ready():
	super._ready()
	# Setze die Position auf den Boden
	position.y = 0.0

func setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2)  # Dunkelgrün
	$Base.material_override = material
	
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.4, 0.2, 0.1)  # Braun
	$Roof.material_override = roof_material
	
	# Scanne initial nach Bäumen
	scan_for_trees()

func _process(delta):
	if not is_active:
		return
		
	plant_timer += delta
	if plant_timer >= PLANT_RATE:
		plant_timer = 0.0
		attempt_plant_tree()

func attempt_plant_tree():
	# Aktualisiere die Liste der Bäume
	scan_for_trees()
	
	# Wenn wir keine Baumstümpfe haben, machen wir nichts
	if stump_positions.is_empty():
		return
		
	# Prüfe den ersten Stumpf
	var stump_pos = stump_positions[0]
	
	# Prüfe ob die Position frei ist
	var too_close = false
	for tree_pos in tree_positions:
		if stump_pos.distance_to(tree_pos) < MIN_TREE_DISTANCE:
			too_close = true
			break
	
	if not too_close:
		stump_positions.pop_front()  # Entferne den Stumpf erst wenn wir ihn nutzen
		plant_tree(stump_pos)
	else:
		# Position ist blockiert, entferne den Stumpf
		stump_positions.pop_front()

func plant_tree(position: Vector3):
	var tree_scene = preload("res://scenes/resources/Resource.tscn")
	var tree = tree_scene.instantiate()
	tree.resource_type = 0  # WOOD type
	get_parent().add_child(tree)
	tree.global_position = Vector3(position.x, 0.5, position.z)  # Setze Y auf 0.5 für die Höhe
	tree_positions.append(position)  # Füge die Position sofort zur Liste hinzu
	# Verbinde das Signal für das Entfernen
	tree.resource_removed.connect(_on_tree_removed.bind())

func scan_for_trees():
	tree_positions.clear()
	
	var space_state = get_world_3d().direct_space_state
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = SCAN_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	
	var results = space_state.intersect_shape(query_params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("get_resource_type"):
			if collider.get_resource_type() == "WOOD":
				tree_positions.append(collider.global_position)  # Nutze die globale Position des Colliders
				# Verbinde das Signal für das Entfernen
				if not collider.resource_removed.is_connected(_on_tree_removed):
					collider.resource_removed.connect(_on_tree_removed.bind())

func _on_tree_removed(pos: Vector3, type: String):
	if not is_inside_tree():
		return
		
	if type == "WOOD":
		# Berechne die lokale Position relativ zum Förster
		var local_pos = pos - global_position
		var distance = local_pos.length()
		
		if distance <= SCAN_RADIUS:
			# Entferne die Position aus der Liste der Baumpositionen
			tree_positions.erase(pos)
			# Füge die Position zur Liste der Baumstümpfe hinzu
			if not stump_positions.has(pos):
				stump_positions.append(pos)
				# Erstelle einen visuellen Baumstumpf
				call_deferred("create_stump", pos)

func create_stump(pos: Vector3):
	if not is_inside_tree():
		return
		
	var stump = CSGCylinder3D.new()
	stump.radius = 0.3
	stump.height = 0.2
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.3, 0.2)  # Braun für Holz
	stump.material = material
	
	# Füge den Stumpf zur Szene hinzu
	add_child(stump)
	
	# Setze die Position relativ zum Förster
	var local_pos = pos - global_position
	stump.position = Vector3(local_pos.x, 0.1, local_pos.z)
	
	# Optional: Füge einen Timer hinzu, um den Stumpf nach einiger Zeit zu entfernen
	var timer = get_tree().create_timer(30.0)  # 30 Sekunden
	timer.timeout.connect(func(): 
		if is_instance_valid(stump) and stump.is_inside_tree():
			stump.queue_free()
	)
