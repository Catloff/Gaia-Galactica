extends Control

@onready var lumbermill_button = $MarginContainer/BuildCategories/BuildButtons/ResourceBuildings/LumbermillButton
@onready var berry_gatherer_button = $MarginContainer/BuildCategories/BuildButtons/ResourceBuildings/BerryGathererButton
@onready var forester_button = $MarginContainer/BuildCategories/BuildButtons/Infrastructure/ForesterButton
@onready var smeltery_button = $MarginContainer/BuildCategories/BuildButtons/Infrastructure/SmelteryButton
@onready var plant_tree_button = $MarginContainer/BuildCategories/BuildButtons/Resources/PlantTreeButton
@onready var demolish_button = $DemolishButton
@onready var resource_manager = get_node("/root/Main/ResourceManager")
@onready var building_manager = get_node("/root/Main/BuildingManager")

signal building_selected(type: String)
signal demolish_mode_changed(enabled: bool)

var current_building: String = ""
var button_mapping = {}

func _ready():
	# Connect building manager signals
	building_manager.buildings_updated.connect(_on_buildings_updated)
	
	# Connect button signals
	lumbermill_button.pressed.connect(_on_building_button_pressed.bind("lumbermill"))
	berry_gatherer_button.pressed.connect(_on_building_button_pressed.bind("berry_gatherer"))
	forester_button.pressed.connect(_on_building_button_pressed.bind("forester"))
	plant_tree_button.pressed.connect(_on_building_button_pressed.bind("plant_tree"))
	smeltery_button.pressed.connect(_on_building_button_pressed.bind("smeltery"))
	demolish_button.pressed.connect(_on_demolish_button_pressed)
	
	# Map buttons to building types
	button_mapping = {
		"lumbermill": lumbermill_button,
		"berry_gatherer": berry_gatherer_button,
		"forester": forester_button,
		"plant_tree": plant_tree_button,
		"smeltery": smeltery_button
	}
	
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
	for type in button_mapping:
		var building = building_manager.get_building_definition(type)
		if building:
			var button = button_mapping[type]
			button.text = "%s %s" % [building.display_name, building.get_cost_text()]
	update_button_states()

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
