extends PanelContainer

@onready var resource_manager = get_node("/root/Main/ResourceManager")
@onready var building_manager = get_node("/root/Main/BuildingManager")

@onready var resource_container = $MarginContainer/VBoxContainer/TabContainer/Ressourcen/ResourceBuildings
@onready var infrastructure_container = $MarginContainer/VBoxContainer/TabContainer/Infrastruktur/Infrastructure
@onready var special_container = $MarginContainer/VBoxContainer/TabContainer/Spezial/Special

signal building_selected(type: String)
signal menu_closed

var current_building: String = ""
var button_mapping = {}

func _ready():
	# Connect building manager signals
	building_manager.buildings_updated.connect(_on_buildings_updated)
	
	# Initialize button states
	call_deferred("_on_buildings_updated")
	resource_manager.resource_changed.connect(_on_resource_changed)
	
	# Verbinde das Sichtbarkeitssignal
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		update_button_states()

func _on_resource_changed(_type: String, _old_value: int, _new_value: int) -> void:
	if visible:
		update_button_states()

func _on_buildings_updated():
	# Clear existing buttons
	for button in button_mapping.values():
		button.queue_free()
	button_mapping.clear()
	
	# Get buildings by category
	var resource_buildings = building_manager.get_buildings_by_category(building_manager.BuildingCategory.RESOURCE)
	var infrastructure_buildings = building_manager.get_buildings_by_category(building_manager.BuildingCategory.INFRASTRUCTURE)
	var special_buildings = building_manager.get_buildings_by_category(building_manager.BuildingCategory.SPECIAL)
	
	# Create buttons for each category
	for building in resource_buildings:
		_create_building_button(building, resource_container)
	
	for building in infrastructure_buildings:
		_create_building_button(building, infrastructure_container)
		
	for building in special_buildings:
		_create_building_button(building, special_container)
	
	if visible:
		update_button_states()

func _create_building_button(building_def, container):
	if not container:
		return
		
	var button = Button.new()
	button.text = "%s %s" % [building_def.display_name, building_def.get_cost_text()]
	button.pressed.connect(_on_building_button_pressed.bind(building_def.type))
	container.add_child(button)
	button_mapping[building_def.type] = button

func update_button_states():
	if not visible:
		return
		
	for type in button_mapping:
		var button = button_mapping[type]
		if button and is_instance_valid(button):
			var can_afford = building_manager.can_afford_building(type)
			button.disabled = not can_afford
			button.modulate = Color(1, 1, 0) if current_building == type else Color(1, 1, 1)

func deselect_building():
	current_building = ""
	building_selected.emit("none")
	if visible:
		update_button_states()

func _on_building_button_pressed(type: String):
	if not visible:
		return
		
	var button = button_mapping.get(type)
	if not button or not is_instance_valid(button):
		return
		
	if button.disabled:
		return
		
	# Wenn das gleiche Gebäude nochmal ausgewählt wird, deselektieren wir es
	if current_building == type:
		deselect_building()
		return
		
	current_building = type
	menu_closed.emit()
	building_selected.emit(type)
	# Verzögere das Verstecken um einen Frame
	call_deferred("hide")
