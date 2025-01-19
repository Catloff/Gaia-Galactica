extends "res://scripts/Resource.gd"

var is_ready_for_harvest: bool = false

func _ready():
	resource_type = ResourceType.WOOD
	resource_amount = 10
	remaining_harvests = MAX_HARVEST
	
	print("[PlantableTree] Initialisiere mit ", MAX_HARVEST, " Ernten")
	
	# Stelle sicher, dass die Kollision aktiviert ist
	collision_layer = 4  # COLLISION_LAYER_BUILDINGS
	collision_mask = 4   # COLLISION_LAYER_BUILDINGS
	
	# Erstelle Baumstumpf und Krone
	var stump = CSGCylinder3D.new()
	stump.radius = 0.3
	stump.height = 0.4
	stump.position.y = 0.2  # Halbe Höhe
	add_child(stump)
	
	var stump_material = StandardMaterial3D.new()
	stump_material.albedo_color = Color(0.4, 0.3, 0.2)  # Braun für Holz
	stump.material = stump_material
	
	var crown = CSGBox3D.new()
	crown.size = Vector3(1.0, 1.0, 1.0)
	crown.position.y = 1.2  # Über dem Stumpf
	crown.name = "Crown"
	add_child(crown)
	
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color(0.2, 0.6, 0.2)  # Grün für Blätter
	crown.material = crown_material
	
	# Speichere die Startposition für das Nachwachsen
	start_position = global_position
	
	# Verzögere die Aktivierung der Ernte um einen Frame
	await get_tree().process_frame
	is_ready_for_harvest = true

func gather_resource():
	if not is_ready_for_harvest:
		print("[PlantableTree] Noch nicht bereit für die Ernte")
		return null
		
	if is_being_removed:
		print("[PlantableTree] Kann nicht geerntet werden - wird gerade entfernt")
		return null
		
	remaining_harvests -= 1
	var resource_name = ResourceType.keys()[resource_type].to_lower()
	print("[PlantableTree] Geerntet: %d Einheiten %s (%d Ernten übrig)" % [resource_amount, resource_name, remaining_harvests])
	
	if remaining_harvests <= 0:
		is_being_removed = true
		print("[PlantableTree] Letzte Ernte - Entferne Baumkrone")
		
		if has_node("Crown"):
			$Crown.queue_free()
		resource_removed.emit(global_position, get_resource_type())
	
	return {
		"type": resource_name,
		"amount": resource_amount
	}

func regrow_tree():
	print("[PlantableTree] Versuche nachwachsen zu lassen...")
	if resource_type == ResourceType.WOOD and not has_node("Crown"):
		print("[PlantableTree] Lasse Baum nachwachsen")
		# Erstelle neue Krone
		var crown = CSGBox3D.new()
		crown.size = Vector3(1.0, 1.0, 1.0)
		crown.position.y = 1.2  # Über dem Stumpf
		crown.name = "Crown"
		
		var crown_material = StandardMaterial3D.new()
		crown_material.albedo_color = Color(0.2, 0.6, 0.2)  # Grün für Blätter
		crown.material = crown_material
		
		add_child(crown)
		
		is_being_removed = false
		remaining_harvests = MAX_HARVEST
		is_ready_for_harvest = true
		print("[PlantableTree] Baum ist nachgewachsen, neue Ernten:", MAX_HARVEST)
	else:
		print("[PlantableTree] Kann nicht nachwachsen - Hat bereits Krone oder falscher Typ") 