extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var fiber_label = $ResourcePanel/MarginContainer/Resources/FiberLabel
@onready var house_button = $BuildPanel/MarginContainer/BuildButtons/HouseButton
@onready var lumbermill_button = $BuildPanel/MarginContainer/BuildButtons/LumbermillButton
@onready var berry_gatherer_button = $BuildPanel/MarginContainer/BuildButtons/BerryGathererButton

signal building_selected(type: String)

var current_building: String = ""
var inventory: Dictionary = {
	"wood": 0,
	"fiber": 0,
	"food": 0
}

func _ready():
	house_button.pressed.connect(_on_house_button_pressed)
	lumbermill_button.pressed.connect(_on_lumbermill_button_pressed)
	berry_gatherer_button.pressed.connect(_on_berry_gatherer_button_pressed)
	update_button_states()

func update_resources(new_inventory: Dictionary) -> void:
	inventory = new_inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	fiber_label.text = "Fiber: %d" % inventory["fiber"]
	update_button_states()

func update_button_states():
	# House: 50 Wood, 10 Fiber
	var can_build_house = inventory["wood"] >= 50 and inventory["fiber"] >= 10
	house_button.disabled = not can_build_house
	
	# Lumbermill: 60 Wood
	var can_build_lumbermill = inventory["wood"] >= 60
	lumbermill_button.disabled = not can_build_lumbermill
	
	# Berry Gatherer: 50 Food
	var can_build_berry_gatherer = inventory["food"] >= 50
	berry_gatherer_button.disabled = not can_build_berry_gatherer
	
	# If current building can't be built anymore, deselect it
	if (current_building == "house" and not can_build_house) or \
	   (current_building == "lumbermill" and not can_build_lumbermill) or \
	   (current_building == "berry_gatherer" and not can_build_berry_gatherer):
		current_building = ""
		building_selected.emit("none")
	
	# Highlight selected building
	house_button.modulate = Color(1, 1, 0) if current_building == "house" else Color(1, 1, 1)
	lumbermill_button.modulate = Color(1, 1, 0) if current_building == "lumbermill" else Color(1, 1, 1)
	berry_gatherer_button.modulate = Color(1, 1, 0) if current_building == "berry_gatherer" else Color(1, 1, 1)

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
