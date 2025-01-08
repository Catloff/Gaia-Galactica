extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var fiber_label = $ResourcePanel/MarginContainer/Resources/FiberLabel
@onready var house_button = $BuildPanel/MarginContainer/BuildButtons/HouseButton
@onready var lumbermill_button = $BuildPanel/MarginContainer/BuildButtons/LumbermillButton

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
	update_button_states()  # Initial-Update der Button-States

func update_resources(new_inventory: Dictionary) -> void:
	inventory = new_inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	fiber_label.text = "Fiber: %d" % inventory["fiber"]
	update_button_states()

func update_button_states():
	# Haus: 50 Holz, 10 Fasern
	var can_build_house = inventory["wood"] >= 50 and inventory["fiber"] >= 10
	house_button.disabled = not can_build_house
	
	# Holzfäller: 60 Holz
	var can_build_lumbermill = inventory["wood"] >= 60
	lumbermill_button.disabled = not can_build_lumbermill
	
	# Wenn das aktuelle Gebäude nicht mehr gebaut werden kann, Auswahl aufheben
	if (current_building == "house" and not can_build_house) or \
	   (current_building == "lumbermill" and not can_build_lumbermill):
		current_building = ""
		building_selected.emit("none")
	
	# Ausgewähltes Gebäude hervorheben
	house_button.modulate = Color(1, 1, 0) if current_building == "house" else Color(1, 1, 1)
	lumbermill_button.modulate = Color(1, 1, 0) if current_building == "lumbermill" else Color(1, 1, 1)

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
