extends "res://scripts/buildings/BaseBuilding.gd"

const PRODUCTION_RATE_BASE = 10.0  # Sekunden pro Produktion
const PRODUCTION_AMOUNT_BASE = 1  # Metall pro Produktion
const WOOD_COST = 5  # Holz pro Produktion
const STONE_COST = 2  # Stein pro Produktion
const PRODUCTION_RADIUS = 15.0  # Reichweite für Ressourcensammlung

var production_timer: float = 0.0

@onready var base_mesh = %Base
@onready var chimney_mesh = %Chimney

func _ready():
	super._ready()
	
	# Registriere als Produktionsgebäude
	add_to_group("buildings")
	
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
		
		# Wenn wir in Reichweite eines Lagers sind, übertrage erst das lokale Lager
		if should_store_directly() and not local_storage.is_empty():
			print("[%s] Übertrage lokales Lager zum Hauptlager" % name)
			transfer_resources_to_main_storage()
		
		# Nur stoppen wenn lokales Lager voll UND kein Lager in Reichweite
		if not should_stop_production():
			attempt_production()

func attempt_production():
	# Prüfe ob wir genug Ressourcen haben
	var required_resources = {"wood": WOOD_COST, "stone": STONE_COST}
	
	# Prüfe ob wir die Ressourcen bekommen können
	if not try_get_resources_from_nearby(required_resources):
		print("[Smeltery] Nicht genug Ressourcen für Produktion")
		return
		
	# Prüfe ob noch Platz im lokalen Lager ist, wenn wir nicht in Lager-Reichweite sind
	if not should_store_directly() and get_total_stored() >= local_storage_capacity:
		print("[Smeltery] Lokales Lager ist voll!")
		return
		
	# Verbrauche die Ressourcen
	if not consume_resources_from_nearby(required_resources):
		print("[Smeltery] Fehler beim Verbrauch der Ressourcen")
		return
	
	# Produziere Metall
	var amount = PRODUCTION_AMOUNT_BASE * get_efficiency_multiplier()
	
	# Wenn die Smeltery in Reichweite eines Lagers ist, produziere direkt ins Hauptlager
	if should_store_directly():
		resource_manager.add_resources({"type": "metal", "amount": amount})
		print("[Smeltery] Produziere %.1f Metall direkt ins Hauptlager" % amount)
	else:
		# Sonst ins lokale Lager
		add_to_local_storage("metal", amount)
		print("[Smeltery] Produziere %.1f Metall ins lokale Lager" % amount)
	
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

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.get_parent() == storage_warning_mesh:
			print("[Smeltery] Ausrufezeichen angeklickt - Übertrage Ressourcen")
			transfer_resources_to_main_storage()

func get_production_radius() -> float:
	return PRODUCTION_RADIUS  # Fester Produktionsradius für die Smeltery

func get_building_radius() -> float:
	return get_production_radius()  # Nutze Produktionsradius für die Reichweitenanzeige

func try_get_resources_from_nearby(required_resources: Dictionary) -> bool:
	# Prüfe zuerst die lokalen Lager der Gebäude
	var total_available = {}
	for resource_type in required_resources:
		total_available[resource_type] = 0.0
		var buildings = get_resource_buildings_in_range(resource_type)
		
		for building in buildings:
			if building.local_storage.has(resource_type):
				total_available[resource_type] += building.local_storage[resource_type]
			elif building.is_in_group("storage_buildings") or building.is_in_group("base"):
				# Wenn es ein Lager ist, prüfe das Hauptlager
				if resource_manager.can_afford({resource_type: required_resources[resource_type]}):
					total_available[resource_type] += resource_manager.get_resource(resource_type)
					break  # Wenn wir aus dem Hauptlager nehmen können, brauchen wir nicht weiter zu suchen
	
	# Prüfe ob wir genug haben
	for resource_type in required_resources:
		if total_available[resource_type] < required_resources[resource_type]:
			return false
	
	return true

func consume_resources_from_nearby(required_resources: Dictionary) -> bool:
	var remaining_needs = required_resources.duplicate()
	
	# Versuche zuerst aus lokalen Lagern zu nehmen
	for resource_type in remaining_needs:
		var amount_needed = remaining_needs[resource_type]
		var buildings = get_resource_buildings_in_range(resource_type)
		
		for building in buildings:
			if amount_needed <= 0:
				break
				
			if building.local_storage.has(resource_type):
				var available = building.local_storage[resource_type]
				var amount_to_take = min(available, amount_needed)
				
				if amount_to_take > 0:
					building.local_storage[resource_type] -= amount_to_take
					amount_needed -= amount_to_take
					building.update_storage_warning()
					print("[%s] Nehme %.1f %s von %s" % [name, amount_to_take, resource_type, building.name])
			elif building.is_in_group("storage_buildings") or building.is_in_group("base"):
				# Wenn es ein Lager ist, nimm aus dem Hauptlager
				if resource_manager.can_afford({resource_type: amount_needed}):
					resource_manager.pay_cost({resource_type: amount_needed})
					print("[%s] Nehme %.1f %s aus dem Hauptlager" % [name, amount_needed, resource_type])
					amount_needed = 0
					break
		
		remaining_needs[resource_type] = amount_needed
	
	# Prüfe ob alle Ressourcen beschafft wurden
	for amount in remaining_needs.values():
		if amount > 0:
			print("[%s] Fehler: Konnte nicht alle benötigten Ressourcen sammeln!" % name)
			return false
	
	return true

func get_resource_buildings_in_range(resource_type: String) -> Array:
	var buildings = []
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	var storage_buildings = get_tree().get_nodes_in_group("storage_buildings")
	var base = get_tree().get_first_node_in_group("base")
	
	print("[%s] Suche nach Gebäuden mit %s in Reichweite (Radius: %.1f)" % [name, resource_type, get_production_radius()])
	
	# Prüfe normale Produktionsgebäude
	for building in all_buildings:
		if building != self and building.is_active:
			var distance = building.global_position.distance_to(global_position)
			if distance <= get_production_radius():
				# Prüfe ob das Gebäude die gesuchte Ressource im lokalen Lager hat
				if building.local_storage.has(resource_type) and building.local_storage[resource_type] > 0:
					print("- Gefunden: %s (Distanz: %.1f) mit %.1f %s" % [
						building.name,
						distance,
						building.local_storage[resource_type],
						resource_type
					])
					buildings.append(building)
	
	# Prüfe Lagergebäude
	for storage in storage_buildings:
		if storage != self and storage.is_active:
			var distance = storage.global_position.distance_to(global_position)
			if distance <= get_production_radius():
				print("- Gefunden: %s (Distanz: %.1f) - Lagergebäude" % [storage.name, distance])
				buildings.append(storage)
	
	# Prüfe Base
	if base and base.is_active:
		var distance = base.global_position.distance_to(global_position)
		if distance <= get_production_radius():
			print("- Gefunden: Base (Distanz: %.1f)" % distance)
			buildings.append(base)
	
	if buildings.is_empty():
		print("- Keine Gebäude mit %s in Reichweite gefunden" % resource_type)
	
	return buildings
