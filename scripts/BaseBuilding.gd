extends Node3D

class_name BaseBuilding

# Grundkosten des Gebäudes
var base_cost: Dictionary = {}

# Upgrade-Kosten als Array von Dictionaries
var upgrade_costs: Array = []

# Gebäude-Level Eigenschaften
var current_level: int = 1
var max_level: int = 1

# Aktivierungsstatus
var is_active: bool = false

# Referenz zum ResourceManager
@onready var resource_manager = get_node("/root/Main/ResourceManager")

# UI Elemente
var upgrade_button: Button
var level_label: Label
var ui: Control

func _ready():
	setup_building()
	setup_ui()
	setup_collision()
	assert(max_level == len(upgrade_costs) + 1)
	
# Virtuelle Methode zum Einrichten des Gebäudes
func setup_building():
	pass

# Einrichten der UI-Elemente
func setup_ui():
	ui = get_node("UI")
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
	if not upgrade_button:
		return
		
	if current_level >= max_level:
		upgrade_button.text = "Max Level"
		upgrade_button.disabled = true
	else:
		var cost = get_upgrade_cost()
		var cost_text = ""
		for resource in cost:
			if cost_text != "":
				cost_text += ", "
			cost_text += "%d %s" % [cost[resource], resource]
		upgrade_button.text = "Upgrade\n(%s)" % cost_text
		upgrade_button.disabled = not can_upgrade()

# Einrichten der Kollision
func setup_collision():
	var static_body = $StaticBody3D
	if static_body:
		static_body.set_script(preload("res://scripts/BuildingBody.gd"))

# Aktivierung des Gebäudes
func activate():
	is_active = true
	
	# Stelle sicher, dass die UI korrekt eingerichtet ist
	if ui:
		ui.top_level = true
		ui.visible = true
		update_ui()
	
	# Verbinde das Signal für Ressourcenänderungen
	if resource_manager:
		if not resource_manager.resource_changed.is_connected(_on_resource_changed):
			resource_manager.resource_changed.connect(_on_resource_changed)
	
	# Aktualisiere UI sofort
	update_ui_position()

# Deaktivierung des Gebäudes
func deactivate():
	is_active = false
	
	# UI ausblenden
	if ui:
		ui.visible = false
	
	# Trenne das Signal für Ressourcenänderungen
	if resource_manager and resource_manager.resource_changed.is_connected(_on_resource_changed):
		resource_manager.resource_changed.disconnect(_on_resource_changed)

# Upgrade-Funktionalität
func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
	var cost = get_upgrade_cost()
	return resource_manager.can_afford(cost)

func get_upgrade_cost() -> Dictionary:
	if current_level >= max_level:
		return {}
	return upgrade_costs[current_level - 1]

func _on_upgrade_pressed():
	upgrade()

func upgrade():
	if not can_upgrade():
		return
		
	var cost = get_upgrade_cost()
	if resource_manager.pay_cost(cost):
		current_level += 1
		update_ui()
		_on_upgrade()

# Virtuelle Methode für Upgrade-Effekte
func _on_upgrade():
	pass

# UI-Update
func update_ui():
	if level_label:
		level_label.text = "Level %d" % current_level
	update_upgrade_button()

# Ressourcen-Änderungs-Handler
func _on_resource_changed(_resource_type: String, _old_value: int, _new_value: int):
	update_upgrade_button()

# Getter für die Gebäudekosten
func get_cost() -> Dictionary:
	return base_cost

# Abriss-Funktionalität
func demolish():
	deactivate()
	queue_free() 
