extends Control

@onready var demolish_button = $DemolishButton
@onready var resource_manager = get_node("/root/Main/ResourceManager")
@onready var building_manager = get_node("/root/Main/BuildingManager")

@onready var resource_container = $MarginContainer/BuildCategories/BuildButtons/ResourceBuildings
@onready var infrastructure_container = $MarginContainer/BuildCategories/BuildButtons/Infrastructure
@onready var special_container = $MarginContainer/BuildCategories/BuildButtons/Special

signal building_selected(type: String)
signal demolish_mode_changed(enabled: bool)

var current_building: String = ""
var button_mapping = {}

func _ready():
	# Connect building manager signals
	building_manager.buildings_updated.connect(_on_buildings_updated)
	demolish_button.pressed.connect(_on_demolish_button_pressed)
	
	# Initialize button states
	call_deferred("_on_buildings_updated")
	resource_manager.resource_changed.connect(_on_resource_changed)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if demolish_button.button_pressed:
				demolish_button.button_pressed = false
				_on_demolish_button_pressed()

func _on_resource_changed(_type: String, _old_value: int, _new_value: int) -> void:
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
	
	update_button_states()

func _create_building_button(building_def, container):
	var button = Button.new()
	button.text = "%s %s" % [building_def.display_name, building_def.get_cost_text()]
	button.pressed.connect(_on_building_button_pressed.bind(building_def.type))
	container.add_child(button)
	button_mapping[building_def.type] = button

func update_button_states():
	for type in button_mapping:
		var button = button_mapping[type]
		var can_afford = building_manager.can_afford_building(type)
		button.disabled = not can_afford
		button.modulate = Color(1, 1, 0) if current_building == type else Color(1, 1, 1)

func deselect_building():
	current_building = ""
	building_selected.emit("none")
	update_button_states()

func _on_demolish_button_pressed():
	print("Abriss-Button gedrückt!")
	demolish_mode_changed.emit(demolish_button.button_pressed)
	if demolish_button.button_pressed:
		deselect_building()

func _on_building_button_pressed(type: String):
	var button = button_mapping[type]
	if button.disabled:
		return
		
	if current_building == type:
		deselect_building()
	else:
		current_building = type
		building_selected.emit(type)
		update_button_states()
