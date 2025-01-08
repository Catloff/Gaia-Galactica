extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var stone_label = $ResourcePanel/MarginContainer/Resources/StoneLabel
@onready var lumbermill_button = $BuildPanel/MarginContainer/BuildCategories/BuildButtons/ResourceBuildings/LumbermillButton
@onready var berry_gatherer_button = $BuildPanel/MarginContainer/BuildCategories/BuildButtons/ResourceBuildings/BerryGathererButton
@onready var forester_button = $BuildPanel/MarginContainer/BuildCategories/BuildButtons/Infrastructure/ForesterButton
@onready var smeltery_button = $BuildPanel/MarginContainer/BuildCategories/BuildButtons/Infrastructure/SmelteryButton
@onready var plant_tree_button = $BuildPanel/MarginContainer/BuildCategories/BuildButtons/Resources/PlantTreeButton
@onready var demolish_button = $BuildPanel/DemolishButton
@onready var metal_label = $ResourcePanel/MarginContainer/Resources/MetalLabel

signal building_selected(type: String)
signal demolish_mode_changed(enabled: bool)

var current_building: String = ""
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"metal": 0
}

func _ready():
	lumbermill_button.pressed.connect(_on_lumbermill_button_pressed)
	berry_gatherer_button.pressed.connect(_on_berry_gatherer_button_pressed)
	forester_button.pressed.connect(_on_forester_button_pressed)
	plant_tree_button.pressed.connect(_on_plant_tree_button_pressed)
	demolish_button.pressed.connect(_on_demolish_button_pressed)
	smeltery_button.pressed.connect(_on_smeltery_button_pressed)
	update_button_states()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if demolish_button.button_pressed:
				demolish_button.button_pressed = false
				_on_demolish_button_pressed()

func update_resources(new_inventory: Dictionary) -> void:
	inventory = new_inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	stone_label.text = "Stone: %d" % inventory["stone"]
	metal_label.text = "Metal: %d" % inventory["metal"]
	update_button_states()

func update_button_states():
	
	# Lumbermill: 60 Wood
	var can_build_lumbermill = inventory["wood"] >= 60
	lumbermill_button.disabled = not can_build_lumbermill
	
	# Berry Gatherer: 50 Food
	var can_build_berry_gatherer = inventory["food"] >= 50
	berry_gatherer_button.disabled = not can_build_berry_gatherer
	
	# Forester: 80 Wood, 20 Stone
	var can_build_forester = inventory["wood"] >= 80 and inventory["stone"] >= 20
	forester_button.disabled = not can_build_forester
	
	# Plant Tree: 10 Wood
	var can_plant_tree = inventory["wood"] >= 10
	plant_tree_button.disabled = not can_plant_tree
	# Smeltery: 80 Wood, 40 Stone
	var can_build_smeltery = inventory["wood"] >= 80 and inventory["stone"] >= 40
	smeltery_button.disabled = not can_build_smeltery
	
	# If current building can't be built anymore, deselect it
	if (current_building == "lumbermill" and not can_build_lumbermill) or \
		(current_building == "berry_gatherer" and not can_build_berry_gatherer) or \
		(current_building == "forester" and not can_build_forester) or \
		(current_building == "plant_tree" and not can_plant_tree) or \
		(current_building == "smeltery" and not can_build_smeltery):
		current_building = ""
		building_selected.emit("none")
	
	# Highlight selected building
	lumbermill_button.modulate = Color(1, 1, 0) if current_building == "lumbermill" else Color(1, 1, 1)
	berry_gatherer_button.modulate = Color(1, 1, 0) if current_building == "berry_gatherer" else Color(1, 1, 1)
	forester_button.modulate = Color(1, 1, 0) if current_building == "forester" else Color(1, 1, 1)
	plant_tree_button.modulate = Color(1, 1, 0) if current_building == "plant_tree" else Color(1, 1, 1)
	smeltery_button.modulate = Color(1, 1, 0) if current_building == "smeltery" else Color(1, 1, 1)

func _on_demolish_button_pressed():
	print("Abriss-Button gedrückt!")
	demolish_mode_changed.emit(demolish_button.button_pressed)
	if demolish_button.button_pressed:
		current_building = ""
		building_selected.emit("none")

func _on_lumbermill_button_pressed():
	if lumbermill_button.disabled:
		return
		
	if current_building == "lumbermill":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "lumbermill"
		building_selected.emit("lumbermill")
	update_button_states()

func _on_berry_gatherer_button_pressed():
	if berry_gatherer_button.disabled:
		return
		
	if current_building == "berry_gatherer":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "berry_gatherer"
		building_selected.emit("berry_gatherer")
	update_button_states()

func _on_forester_button_pressed():
	if forester_button.disabled:
		return
		
	if current_building == "forester":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "forester"
		building_selected.emit("forester")
	update_button_states()

func _on_plant_tree_button_pressed():
	if plant_tree_button.disabled:
		return
		
	if current_building == "plant_tree":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "plant_tree"
		building_selected.emit("plant_tree")
	update_button_states()

func _on_smeltery_button_pressed():
	if smeltery_button.disabled:
		return
		
	if current_building == "smeltery":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "smeltery"
		building_selected.emit("smeltery")
	update_button_states()
