extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var stone_label = $ResourcePanel/MarginContainer/Resources/StoneLabel
@onready var house_button = $BuildPanel/MarginContainer/BuildButtons/HouseButton
@onready var lumbermill_button = $BuildPanel/MarginContainer/BuildButtons/LumbermillButton
@onready var berry_gatherer_button = $BuildPanel/MarginContainer/BuildButtons/BerryGathererButton
@onready var forester_button = $BuildPanel/MarginContainer/BuildButtons/ForesterButton
@onready var plant_tree_button = $BuildPanel/MarginContainer/BuildButtons/PlantTreeButton

signal building_selected(type: String)

var current_building: String = ""
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0
}

func _ready():
	house_button.pressed.connect(_on_house_button_pressed)
	lumbermill_button.pressed.connect(_on_lumbermill_button_pressed)
	berry_gatherer_button.pressed.connect(_on_berry_gatherer_button_pressed)
	forester_button.pressed.connect(_on_forester_button_pressed)
	plant_tree_button.pressed.connect(_on_plant_tree_button_pressed)
	update_button_states()

func update_resources(new_inventory: Dictionary) -> void:
	inventory = new_inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	stone_label.text = "Stone: %d" % inventory["stone"]
	update_button_states()

func update_button_states():
	# House: 50 Wood, 10 Stone
	var can_build_house = inventory["wood"] >= 50 and inventory["stone"] >= 10
	house_button.disabled = not can_build_house
	
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
	
	# If current building can't be built anymore, deselect it
	if (current_building == "house" and not can_build_house) or \
	   (current_building == "lumbermill" and not can_build_lumbermill) or \
	   (current_building == "berry_gatherer" and not can_build_berry_gatherer) or \
	   (current_building == "forester" and not can_build_forester) or \
	   (current_building == "plant_tree" and not can_plant_tree):
		current_building = ""
		building_selected.emit("none")
	
	# Highlight selected building
	house_button.modulate = Color(1, 1, 0) if current_building == "house" else Color(1, 1, 1)
	lumbermill_button.modulate = Color(1, 1, 0) if current_building == "lumbermill" else Color(1, 1, 1)
	berry_gatherer_button.modulate = Color(1, 1, 0) if current_building == "berry_gatherer" else Color(1, 1, 1)
	forester_button.modulate = Color(1, 1, 0) if current_building == "forester" else Color(1, 1, 1)
	plant_tree_button.modulate = Color(1, 1, 0) if current_building == "plant_tree" else Color(1, 1, 1)

func _on_house_button_pressed():
	if house_button.disabled:
		return
		
	if current_building == "house":
		current_building = ""
		building_selected.emit("none")
	else:
		current_building = "house"
		building_selected.emit("house")
	update_button_states()

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
