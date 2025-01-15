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

# Referenz zum ResourceManager
@onready var resource_manager = get_node("/root/Main/ResourceManager")

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

func _ready():
	setup_building()
	setup_ui()
	setup_collision()
	setup_range_indicator()
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

# Einrichten der Kollision
func setup_collision():
	var static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		# Wenn kein StaticBody3D existiert, erstelle einen
		static_body = StaticBody3D.new()
		static_body.name = "StaticBody3D"
		
		# Füge eine CollisionShape hinzu
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(2, 2, 2)  # Standard-Größe
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		
		add_child(static_body)
	
	# Stelle sicher, dass das BuildingBody-Skript angehängt ist
	if not static_body.get_script():
		static_body.set_script(preload("res://scripts/buildings/BuildingBody.gd"))
	
	# Aktiviere Kollision
	static_body.collision_layer = 1
	static_body.collision_mask = 1

func _on_upgrade_pressed():
	upgrade()
