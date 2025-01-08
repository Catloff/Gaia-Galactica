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
@onready var upgrade_button = $UI/UpgradeButton
@onready var level_label = $UI/LevelLabel
@onready var ui = $UI

func _ready():
	print("[BaseBuilding] _ready für: ", name)
	setup_building()
	setup_ui()
	setup_collision()
	print("[BaseBuilding] Nach Setup - Upgrade Kosten: ", upgrade_costs)
	print("[BaseBuilding] Nach Setup - Max Level: ", max_level)

# Virtuelle Methode zum Einrichten des Gebäudes
func setup_building():
	pass

# Einrichten der UI-Elemente
func setup_ui():
	print("[BaseBuilding] Setup UI für: ", name)
	if not ui:
		print("[BaseBuilding] FEHLER: Keine UI gefunden!")
		return
		
	print("[BaseBuilding] UI Node gefunden: ", ui.name)
	# Verstecke UI initial
	ui.visible = false
	ui.top_level = true  # Stellt sicher, dass die UI immer im Vordergrund ist
	
	if level_label:
		print("[BaseBuilding] Level Label gefunden")
		level_label.text = "Level %d" % current_level
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		print("[BaseBuilding] FEHLER: Kein Level Label gefunden!")
		
	if upgrade_button:
		print("[BaseBuilding] Upgrade Button gefunden")
		upgrade_button.pressed.connect(_on_upgrade_pressed)
		update_upgrade_button()
	else:
		print("[BaseBuilding] FEHLER: Kein Upgrade Button gefunden!")

func _process(_delta):
	if is_active:
		update_ui_position()

func update_ui_position():
	if not ui or not is_active:
		return
		
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("[BaseBuilding] FEHLER: Keine Kamera gefunden!")
		return
		
	# Position über dem Gebäude berechnen
	var screen_pos = camera.unproject_position(global_position + Vector3(0, 1.5, 0))
	
	# Debug: Kamera und Gebäude Positionen
	print("[BaseBuilding] Kamera Position: ", camera.global_position)
	print("[BaseBuilding] Gebäude Position: ", global_position)
	
	# Vektor von der Kamera zum Gebäude
	var to_building = global_position - camera.global_position
	var camera_forward = -camera.global_transform.basis.z
	
	# Debug: Vektoren
	print("[BaseBuilding] Vektor zum Gebäude: ", to_building)
	print("[BaseBuilding] Kamera Vorwärts: ", camera_forward)
	
	# Berechne den Winkel zwischen den Vektoren
	var dot_product = to_building.normalized().dot(camera_forward)
	print("[BaseBuilding] Dot Product: ", dot_product)
	
	# Wenn der Winkel kleiner als 90 Grad ist (dot product > 0), ist das Gebäude vor der Kamera
	if dot_product > 0:
		ui.visible = true
		ui.position = screen_pos
		print("[BaseBuilding] UI sichtbar gemacht - Position: ", screen_pos)
	else:
		ui.visible = false
		print("[BaseBuilding] UI versteckt - Gebäude außerhalb des Sichtfelds")

func update_upgrade_button():
	if not upgrade_button:
		print("[BaseBuilding] FEHLER: Kein Upgrade Button zum Aktualisieren!")
		return
		
	print("[BaseBuilding] Aktualisiere Upgrade Button - Level: ", current_level, "/", max_level)
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
		upgrade_button.text = "Upgrade (%s)" % cost_text
		upgrade_button.disabled = not can_upgrade()
	print("[BaseBuilding] Button Text: ", upgrade_button.text, " Disabled: ", upgrade_button.disabled)

# Einrichten der Kollision
func setup_collision():
	var static_body = $StaticBody3D
	if static_body:
		static_body.set_script(preload("res://scripts/BuildingBody.gd"))

# Aktivierung des Gebäudes
func activate():
	print("[BaseBuilding] Aktiviere Gebäude: ", name)
	is_active = true
	
	# Stelle sicher, dass die UI korrekt eingerichtet ist
	if ui:
		print("[BaseBuilding] UI gefunden, mache sichtbar")
		ui.top_level = true
		ui.visible = true
		update_ui()
	else:
		print("[BaseBuilding] FEHLER: Keine UI zum Aktivieren gefunden!")
	
	# Verbinde das Signal für Ressourcenänderungen
	if resource_manager:
		if not resource_manager.resource_changed.is_connected(_on_resource_changed):
			resource_manager.resource_changed.connect(_on_resource_changed)
	
	# Aktualisiere UI sofort
	update_ui_position()
	print("[BaseBuilding] Aktivierung abgeschlossen - UI sichtbar: ", ui.visible if ui else "Keine UI")

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