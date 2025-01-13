extends Control

var current_building: BaseBuilding = null
@onready var building_manager = get_node("/root/Main/BuildingManager")
@onready var building_name_label = %BuildingName
@onready var level_label = %Level
@onready var production_rate_label = %ProductionRate
@onready var efficiency_label = %EfficiencyMultiplier
@onready var speed_label = %SpeedMultiplier
@onready var upgrade_button = %UpgradeButton
@onready var close_button = %CloseButton
@onready var mobile_navigation = $"../MobileNavigation"

func _ready():
	# Setze Z-Index höher als andere HUD-Elemente
	z_index = 100
	
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Verbinde die Mobile Navigation Signale
	if mobile_navigation:
		mobile_navigation.build_button.pressed.connect(_on_mobile_nav_button_pressed)
		mobile_navigation.demolish_button.pressed.connect(_on_mobile_nav_button_pressed)
	
	# Verbinde das BuildingManager Signal
	if building_manager:
		building_manager.preview_building_changed.connect(_on_preview_building_changed)
	
	hide()
	print("[BuildingInfoHUD] Initialisiert")

func _on_preview_building_changed(preview: BaseBuilding):
	if preview:
		print("[BuildingInfoHUD] Zeige Preview-Building Info")
		show_building_info(preview)
	else:
		print("[BuildingInfoHUD] Verstecke Preview-Building Info")
		show_building_info(null)

func _on_mobile_nav_button_pressed():
	print("[BuildingInfoHUD] Mobile Navigation Button gedrückt - schließe HUD")
	show_building_info(null)

func show_building_info(building: BaseBuilding):
	if not building:
		hide()
		current_building = null
		# Wenn wir ein Preview-Building haben und das HUD geschlossen wird, brechen wir den Bauvorgang ab
		if building_manager and building_manager.preview_building:
			building_manager.cancel_building()
		return
		
	# Wenn das gleiche Gebäude nochmal angeklickt wird, schließen wir das HUD
	if current_building == building and not building_manager.preview_building:
		print("[BuildingInfoHUD] Gleiches Gebäude angeklickt - schließe HUD")
		hide()
		current_building = null
		return
		
	print("[BuildingInfoHUD] Zeige Info für Gebäude: ", building.name)
	current_building = building
	show()
	_update_info()

func _update_info():
	if not current_building:
		return
		
	building_name_label.text = current_building.name
	level_label.text = "Level: %d" % current_building.current_level
	
	if current_building.has_method("get_production_rate"):
		production_rate_label.text = "Rate: %.1f Sek" % current_building.get_production_rate()
	else:
		production_rate_label.text = "Rate: -"
		
	if current_building.has_method("get_efficiency_multiplier"):
		efficiency_label.text = "Effizienz: %.2fx" % current_building.get_efficiency_multiplier()
	else:
		efficiency_label.text = "Effizienz: -"
		
	if current_building.has_method("get_speed_multiplier"):
		speed_label.text = "Geschwindigkeit: %.2fx" % current_building.get_speed_multiplier()
	else:
		speed_label.text = "Geschwindigkeit: -"
		
	# Deaktiviere den Upgrade-Button während der Bauvorschau
	if building_manager and building_manager.preview_building == current_building:
		upgrade_button.disabled = true
		upgrade_button.text = "Upgrade"
		return
		
	# Prüfe ob ein Upgrade möglich ist
	if current_building.can_upgrade():
		upgrade_button.disabled = false
		var costs = current_building.get_upgrade_costs()
		var cost_text = "Upgrade ("
		for resource in costs:
			cost_text += "%d %s, " % [costs[resource], resource]
		cost_text = cost_text.trim_suffix(", ") + ")"
		upgrade_button.text = cost_text
	else:
		upgrade_button.disabled = true
		if current_building.current_level >= current_building.max_level:
			upgrade_button.text = "Max Level erreicht"
		else:
			upgrade_button.text = "Upgrade"

func _on_upgrade_pressed():
	if current_building and current_building.can_upgrade():
		current_building.upgrade()
		_update_info()

func _on_close_pressed():
	show_building_info(null)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[BuildingInfoHUD] Mausklick erkannt")
		var camera = get_viewport().get_camera_3d()
		if not camera:
			print("[BuildingInfoHUD] Keine Kamera gefunden!")
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_tree().root.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		# Setze die Kollisionsmaske auf 1 (Standard-Layer)
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		
		if result:
			print("[BuildingInfoHUD] Raycast Treffer: ", result.collider)
			# Prüfe, ob der Collider ein StaticBody3D ist und einen BaseBuilding als Parent hat
			if result.collider is StaticBody3D and result.collider.get_parent() is BaseBuilding:
				print("[BuildingInfoHUD] Gebäude gefunden!")
				show_building_info(result.collider.get_parent())
			elif not get_rect().has_point(event.position):
				# Wenn wir nicht auf das HUD selbst geklickt haben, schließen wir es
				show_building_info(null)
		else:
			print("[BuildingInfoHUD] Kein Raycast Treffer")
			# Wenn wir ins Leere geklickt haben und nicht auf das HUD selbst, schließen wir es
			if not get_rect().has_point(event.position):
				show_building_info(null) 
