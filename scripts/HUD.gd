extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var stone_label = $ResourcePanel/MarginContainer/Resources/StoneLabel
@onready var metal_label = $ResourcePanel/MarginContainer/Resources/MetalLabel
@onready var house_button = $BuildPanel/MarginContainer/BuildButtons/HouseButton
@onready var lumbermill_button = $BuildPanel/MarginContainer/BuildButtons/LumbermillButton
@onready var berry_gatherer_button = $BuildPanel/MarginContainer/BuildButtons/BerryGathererButton
@onready var smeltery_button = $BuildPanel/MarginContainer/BuildButtons/SmelteryButton

signal building_selected(type: String)

var current_building: String = ""
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"metal": 0
}

func _ready():
	house_button.pressed.connect(_on_house_button_pressed)
	lumbermill_button.pressed.connect(_on_lumbermill_button_pressed)
	berry_gatherer_button.pressed.connect(_on_berry_gatherer_button_pressed)
	smeltery_button.pressed.connect(_on_smeltery_button_pressed)
	update_button_states()

func update_resources(new_inventory: Dictionary) -> void:
	inventory = new_inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	stone_label.text = "Stone: %d" % inventory["stone"]
	metal_label.text = "Metal: %d" % inventory["metal"]
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
	
	# Smeltery: 80 Wood, 40 Stone
	var can_build_smeltery = inventory["wood"] >= 80 and inventory["stone"] >= 40
	smeltery_button.disabled = not can_build_smeltery
	
	# If current building can't be built anymore, deselect it
	if (current_building == "house" and not can_build_house) or \
	   (current_building == "lumbermill" and not can_build_lumbermill) or \
	   (current_building == "berry_gatherer" and not can_build_berry_gatherer) or \
	   (current_building == "smeltery" and not can_build_smeltery):
		current_building = ""
		building_selected.emit("none")
	
	# Highlight selected building
	house_button.modulate = Color(1, 1, 0) if current_building == "house" else Color(1, 1, 1)
	lumbermill_button.modulate = Color(1, 1, 0) if current_building == "lumbermill" else Color(1, 1, 1)
	berry_gatherer_button.modulate = Color(1, 1, 0) if current_building == "berry_gatherer" else Color(1, 1, 1)
	smeltery_button.modulate = Color(1, 1, 0) if current_building == "smeltery" else Color(1, 1, 1)

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
