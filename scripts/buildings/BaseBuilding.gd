extends Node3D

class_name BaseBuilding

# Upgrade-Kosten als Array von Dictionaries
var upgrade_costs: Array = []

# Gebäude-Level Eigenschaften
var current_level: int = 1
var max_level: int = 1

# Aktivierungsstatus
var is_active: bool = false

# Radius-Indikator
var range_indicator: MeshInstance3D

# Lokales Zwischenlager
var local_storage: Dictionary = {}
var local_storage_capacity: int = 50
var storage_warning_mesh: MeshInstance3D
var has_storage_warning: bool = false

# Referenz zum ResourceManager
@onready var resource_manager = get_node("/root/Main/ResourceManager")

# Kollisionsmasken
const COLLISION_LAYER_GROUND = 2
const COLLISION_LAYER_BUILDINGS = 4

# Virtuelle Methoden für Gebäude-Eigenschaften
func get_production_rate() -> float:
	return 0.0

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * (current_level - 1))  # 25% mehr pro Level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * (current_level - 1))  # 20% schneller pro Level

func get_building_radius() -> float:
	return 5.0  # Standard-Radius, kann von Kindklassen überschrieben werden

# UI Elemente
var upgrade_button: Button
var level_label: Label
var ui: Control

const STORAGE_CHECK_RADIUS = 10.0  # Radius für Lagerprüfung

var had_storage_in_range: bool = false  # Speichert den letzten Lagerstatus

var is_storing_directly: bool = false  # Speichert ob wir bereits auf direkte Speicherung umgeschaltet haben

func _ready():
	setup_building()
	setup_ui()
	setup_collision()
	setup_range_indicator()
	setup_storage_warning()
	assert(max_level == len(upgrade_costs) + 1)
	
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)

func setup_range_indicator():
	range_indicator = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = get_building_radius()
	cylinder.bottom_radius = get_building_radius()
	cylinder.height = 0.1
	range_indicator.mesh = cylinder
	
	# Material zur Laufzeit erstellen
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.8, 1, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.8, 1, 1)
	material.emission_energy_multiplier = 0.5
	
	range_indicator.material_override = material
	range_indicator.visible = false
	add_child(range_indicator)

func setup_storage_warning():
	storage_warning_mesh = MeshInstance3D.new()
	var warning_mesh = PrismMesh.new()
	warning_mesh.size = Vector3(1.8, 2.2, 0.1)
	storage_warning_mesh.mesh = warning_mesh
	
	var warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = Color(1, 0.8, 0, 1)  # Gelb
	warning_material.emission_enabled = true
	warning_material.emission = Color(1, 0.8, 0)
	warning_material.emission_energy_multiplier = 0.5
	
	storage_warning_mesh.material_override = warning_material
	storage_warning_mesh.position = Vector3(0, 3, 0)  # Über dem Gebäude
	storage_warning_mesh.visible = false
	
	# Füge StaticBody3D zum storage_warning_mesh hinzu
	var warning_body = StaticBody3D.new()
	warning_body.collision_layer = 16  # Layer 5 für Ausrufezeichen
	warning_body.collision_mask = 0  # Keine Kollision mit anderen Objekten
	
	var warning_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.8, 2.2, 0.1)
	warning_shape.shape = shape
	warning_body.add_child(warning_shape)
	storage_warning_mesh.add_child(warning_body)
	
	add_child(storage_warning_mesh)

func has_storage_in_range() -> bool:
	var buildings = get_tree().get_nodes_in_group("storage_buildings")
	var base = get_tree().get_first_node_in_group("base")
	
	# Prüfe Base zuerst
	if base and base.is_active:
		var distance = base.global_position.distance_to(global_position)
		if distance <= base.get_storage_radius():  # Nutze die Base-Reichweite
			return true
	
	# Dann prüfe andere Lagergebäude
	for storage in buildings:
		if storage != self and storage.is_active:
			var distance = storage.global_position.distance_to(global_position)
			if distance <= storage.get_storage_radius():  # Nutze die Lager-Reichweite
				return true
	
	return false

func add_to_local_storage(resource_type: String, amount: float) -> float:
	if not local_storage.has(resource_type):
		local_storage[resource_type] = 0.0
	
	var space_left = local_storage_capacity - get_total_stored()
	var amount_to_store = min(amount, space_left)
	
	if amount_to_store > 0:
		local_storage[resource_type] += amount_to_store
		update_storage_warning()
	
	return amount - amount_to_store  # Gibt überschüssige Menge zurück

func get_total_stored() -> float:
	var total = 0.0
	for resource in local_storage.values():
		total += resource
	return total

func update_storage_warning():
	var total_stored = get_total_stored()
	var is_nearly_full = total_stored >= local_storage_capacity * 0.8  # 80% voll
	var has_storage = has_storage_in_range()
	
	# Zeige Warnung nur wenn fast voll UND kein Lager in Reichweite
	if is_nearly_full and not has_storage:
		if not has_storage_warning:
			print("[%s] Lager-Status Update:" % name)
			print("- Gespeicherte Menge: %.1f/%.1f (%.1f%%)" % [total_stored, local_storage_capacity, (total_stored/local_storage_capacity * 100)])
			print("- Lager in Reichweite: %s" % has_storage)
			print("- Zeige Ausrufezeichen an")
			storage_warning_mesh.visible = true
			has_storage_warning = true
	else:
		if has_storage_warning or storage_warning_mesh.visible:
			print("[%s] Lager-Status Update:" % name)
			print("- Gespeicherte Menge: %.1f/%.1f (%.1f%%)" % [total_stored, local_storage_capacity, (total_stored/local_storage_capacity * 100)])
			print("- Lager in Reichweite: %s" % has_storage)
			if storage_warning_mesh.visible:
				print("- Verstecke Ausrufezeichen")
			storage_warning_mesh.visible = false
			has_storage_warning = false

func transfer_resources_to_main_storage():
	if local_storage.is_empty():
		return
		
	print("[%s] Übertrage Ressourcen zum Hauptlager:" % name)
	for resource_type in local_storage.keys():
		var amount = local_storage[resource_type]
		if amount > 0:
			print("- %s: %.1f" % [resource_type, amount])
			resource_manager.add_resources({"type": resource_type, "amount": amount})
			local_storage[resource_type] = 0
	
	update_storage_warning()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if not camera:
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 16  # Nur mit Layer 5 (Ausrufezeichen) kollidieren
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.get_parent() == storage_warning_mesh:
			print("[%s] Ausrufezeichen wurde angeklickt:" % name)
			print("- Klick-Position: %s" % event.position)
			print("- Kollision mit: %s" % result.collider.name)
			transfer_resources_to_main_storage()

func should_store_directly() -> bool:
	return has_storage_in_range()

func _physics_process(_delta):
	if is_active:
		var has_storage = has_storage_in_range()
		
		# Debug-Ausgabe nur bei Statusänderungen
		if has_storage != had_storage_in_range:
			print("[%s] Lager-Status geändert:" % name)
			print("- Vorher in Reichweite: %s" % had_storage_in_range)
			print("- Jetzt in Reichweite: %s" % has_storage)
			
			if has_storage:
				var base = get_tree().get_first_node_in_group("base")
				var storage = get_tree().get_nodes_in_group("storage_buildings").filter(func(s): return s != self and s.is_active)[0] if not get_tree().get_nodes_in_group("storage_buildings").is_empty() else null
				
				if base and base.is_active and base.global_position.distance_to(global_position) <= STORAGE_CHECK_RADIUS:
					print("- Base in Reichweite (Distanz: %.1f)" % base.global_position.distance_to(global_position))
				elif storage:
					print("- Lager in Reichweite (Distanz: %.1f)" % storage.global_position.distance_to(global_position))
			
			print("- Lokaler Lagerinhalt: %s" % local_storage)
			
			# Wenn ein Lager in Reichweite gekommen ist
			if has_storage and not had_storage_in_range:
				print("[%s] Übertrage Ressourcen zum Hauptlager" % name)
				transfer_resources_to_main_storage()
				storage_warning_mesh.visible = false
				has_storage_warning = false
		
		had_storage_in_range = has_storage
		update_storage_warning()

# Virtuelle Methode zum Einrichten des Gebäudes
func setup_building():
	# Upgrade-System ist deaktiviert
	if upgrade_button:
		upgrade_button.visible = false
	if level_label:
		level_label.visible = false
	
	# Gebäude-spezifische Einrichtung
	_setup_building()

func setup_ui():
	ui = get_node_or_null("UI")
	if not ui:
		return
	level_label = $UI/LevelLabel
	upgrade_button = $UI/UpgradeButton
	
	# Verstecke UI initial
	ui.visible = false
	ui.top_level = true  # Stellt sicher, dass die UI immer im Vordergrund ist
	
	if level_label:
		level_label.text = "Level %d" % current_level
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
		update_upgrade_button()

func _process(_delta):
	if is_active:
		update_ui_position()

func update_ui_position():
	if not ui or not is_active:
		return
		
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
		
	# Position über dem Gebäude berechnen
	var screen_pos = camera.unproject_position(global_position + Vector3(0, 1.5, 0))
	
	# Vektor von der Kamera zum Gebäude
	var to_building = global_position - camera.global_position
	var camera_forward = -camera.global_transform.basis.z
	
	# Berechne den Winkel zwischen den Vektoren
	var dot_product = to_building.normalized().dot(camera_forward)
	
	# Wenn der Winkel kleiner als 90 Grad ist (dot product > 0), ist das Gebäude vor der Kamera
	if dot_product > 0:
		ui.visible = true
		ui.position = screen_pos
	else:
		ui.visible = false

func update_upgrade_button():
	if not is_instance_valid(upgrade_button) or current_level >= max_level:
		return
		
	var can_be_upgraded = false
	if current_level < max_level:
		var upgrade_cost = upgrade_costs[current_level - 1]
		can_be_upgraded = resource_manager.can_afford(upgrade_cost)
	
	upgrade_button.disabled = not can_be_upgraded

func activate():
	is_active = true
	
	# Stelle sicher, dass die UI korrekt eingerichtet ist
	if ui:
		ui.top_level = true
		ui.visible = true
		update_ui()
	
	# Range-Indikator initial ausblenden
	if range_indicator:
		range_indicator.visible = false
	
	# Verbinde das Signal für Ressourcenänderungen
	if resource_manager:
		if not resource_manager.resources_updated.is_connected(_on_resources_updated):
			resource_manager.resources_updated.connect(_on_resources_updated)
	
	# Aktualisiere UI sofort
	update_ui_position()

func show_range_indicator(should_show: bool):
	if range_indicator:
		range_indicator.visible = should_show

func deactivate():
	is_active = false
	
	# UI ausblenden
	if ui:
		ui.visible = false
	
	if range_indicator:
		range_indicator.visible = false
	
	# Trenne das Signal für Ressourcenänderungen
	if resource_manager and resource_manager.resources_updated.is_connected(_on_resources_updated):
		resource_manager.resources_updated.disconnect(_on_resources_updated)

func _on_resources_updated():
	update_upgrade_button()

func get_upgrade_costs() -> Dictionary:
	if current_level >= max_level:
		return {}
	return upgrade_costs[current_level - 1]

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var next_level_costs = upgrade_costs[current_level - 1]
	return resource_manager.can_afford(next_level_costs)

func upgrade() -> bool:
	if current_level >= max_level:
		return false
		
	var upgrade_cost = upgrade_costs[current_level - 1]
	if not resource_manager.pay_cost(upgrade_cost):
		return false
		
	current_level += 1
	
	if level_label:
		level_label.text = "Level %d" % current_level
	
	if upgrade_button and current_level >= max_level:
		upgrade_button.visible = false
	
	_on_upgrade()
	return true

func update_ui():
	if level_label:
		level_label.text = "Level %d" % current_level

# Abriss-Funktionalität
func demolish():
	print("[BaseBuilding] Beginne Abriss von: ", name)
	deactivate()
	
	# Deaktiviere zuerst die Kollision
	var static_body = get_node_or_null("StaticBody3D")
	if static_body:
		print("[BaseBuilding] Deaktiviere Kollision für: ", name)
		static_body.collision_layer = 0
		static_body.collision_mask = 0
		if static_body.get_child_count() > 0:
			for child in static_body.get_children():
				child.queue_free()
		static_body.queue_free()
	
	# Gib alle visuellen Ressourcen frei
	var visual = get_node_or_null("Visual")
	if visual:
		for child in visual.get_children():
			if child is MeshInstance3D:
				# Setze das Material auf null anstatt es zu löschen
				child.material_override = null
				child.queue_free()
		visual.queue_free()
	
	# Entferne das Gebäude selbst
	queue_free()
	print("[BaseBuilding] Gebäude erfolgreich abgerissen")

# Virtuelle Methode für gebäude-spezifische Einrichtung
func _setup_building():
	pass

func _on_upgrade():
	pass

# Virtuelle Methode zum Einrichten der Kollision
func setup_collision():
	print("[BaseBuilding] Richte Kollision ein für: ", name)
	var static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		# Wenn kein StaticBody3D existiert, erstelle einen
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		static_body.collision_layer = COLLISION_LAYER_BUILDINGS  # Layer für Gebäude
		static_body.collision_mask = COLLISION_LAYER_BUILDINGS
		print("[BaseBuilding] Neuer StaticBody3D erstellt mit Kollisionsmaske: ", COLLISION_LAYER_BUILDINGS)
		
		# Füge eine CollisionShape hinzu
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2, 2, 2)  # Standard-Größe
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		add_child(static_body)
	else:
		# Aktualisiere die Kollisionsmaske des existierenden StaticBody
		static_body.collision_layer = COLLISION_LAYER_BUILDINGS
		static_body.collision_mask = COLLISION_LAYER_BUILDINGS
		print("[BaseBuilding] Existierender StaticBody3D aktualisiert mit Kollisionsmaske: ", COLLISION_LAYER_BUILDINGS)
	
	# Stelle sicher, dass das BuildingBody-Skript angehängt ist
	if not static_body.get_script():
		static_body.set_script(preload("res://scripts/buildings/BuildingBody.gd"))
		print("[BaseBuilding] BuildingBody-Skript an StaticBody3D angehängt")

func _on_upgrade_pressed():
	upgrade()

func is_local_storage_full() -> bool:
	return get_total_stored() >= local_storage_capacity

func should_stop_production() -> bool:
	# Nur stoppen wenn lokales Lager voll UND kein Lager in Reichweite
	return is_local_storage_full() and not has_storage_in_range()

func find_storage_in_range():
	var buildings = get_tree().get_nodes_in_group("storage_buildings")
	var base = get_tree().get_first_node_in_group("base")
	
	# Prüfe Base zuerst
	if base and base.global_position.distance_to(global_position) <= STORAGE_CHECK_RADIUS:
		return base
	
	# Dann prüfe andere Lagergebäude
	for storage in buildings:
		if storage.global_position.distance_to(global_position) <= STORAGE_CHECK_RADIUS:
			return storage
	
	return null

func stop_production():
	is_active = false

func has_storage_space_in_range() -> bool:
	var storage = find_storage_in_range()
	return storage != null and not storage.is_full()

# Hilfsfunktion zum direkten Hinzufügen von Ressourcen
func add_resources(resource_type: String, amount: float) -> void:
	if should_store_directly():
		# Wenn wir noch nicht auf direkte Speicherung umgeschaltet haben
		if not is_storing_directly:
			# Übertrage erst das interne Lager wenn nötig
			if not local_storage.is_empty():
				print("[%s] Wechsel zu direkter Speicherung - Übertrage internes Lager zuerst:" % name)
				transfer_resources_to_main_storage()
			is_storing_directly = true
		
		# Dann füge die neuen Ressourcen direkt hinzu
		resource_manager.add_resources({"type": resource_type, "amount": amount})
		print("[%s] Direkte Speicherung: %s +%.1f" % [name, resource_type, amount])
	else:
		# Wenn kein Lager mehr in Reichweite ist, setze den Status zurück
		is_storing_directly = false
		# Speichere ins lokale Lager
		var overflow = add_to_local_storage(resource_type, amount)
		if overflow > 0:
			print("[%s] Lokales Lager voll - Überschuss: %s %.1f" % [name, resource_type, overflow])

# Virtuelle Methode für den Produktionsradius
func get_production_radius() -> float:
	return 10.0  # Standard-Produktionsradius, kann von Kindklassen überschrieben werden

func get_resource_buildings_in_range(resource_type: String) -> Array:
	var buildings = []
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	
	print("[%s] Suche nach Gebäuden mit %s in Reichweite (Radius: %.1f)" % [name, resource_type, get_production_radius()])
	
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
	
	if buildings.is_empty():
		print("- Keine Gebäude mit %s in Reichweite gefunden" % resource_type)
	
	return buildings

func try_get_resources_from_nearby(required_resources: Dictionary) -> bool:
	# Wenn ein Lager in Reichweite ist, nutze das Hauptlager
	if has_storage_in_range():
		return resource_manager.can_afford(required_resources)
	
	# Sonst prüfe ob alle benötigten Ressourcen von Gebäuden in Reichweite kommen können
	for resource_type in required_resources:
		var amount_needed = required_resources[resource_type]
		var buildings = get_resource_buildings_in_range(resource_type)
		var total_available = 0.0
		
		for building in buildings:
			total_available += building.local_storage[resource_type]
		
		if total_available < amount_needed:
			return false
	
	return true

func consume_resources_from_nearby(required_resources: Dictionary) -> bool:
	# Wenn ein Lager in Reichweite ist, nutze das Hauptlager
	if has_storage_in_range():
		return resource_manager.pay_cost(required_resources)
	
	# Sonst hole Ressourcen von Gebäuden in Reichweite
	for resource_type in required_resources:
		var amount_needed = required_resources[resource_type]
		var buildings = get_resource_buildings_in_range(resource_type)
		
		for building in buildings:
			if amount_needed <= 0:
				break
				
			var available = building.local_storage[resource_type]
			var amount_to_take = min(available, amount_needed)
			
			building.local_storage[resource_type] -= amount_to_take
			amount_needed -= amount_to_take
			
			print("[%s] Nehme %.1f %s von %s" % [name, amount_to_take, resource_type, building.name])
		
		if amount_needed > 0:
			print("[%s] Fehler: Konnte nicht genug %s sammeln!" % [name, resource_type])
			return false
	
	return true
