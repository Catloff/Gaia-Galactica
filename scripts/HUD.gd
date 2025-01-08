extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var fiber_label = $ResourcePanel/MarginContainer/Resources/FiberLabel
@onready var build_button = $BuildPanel/MarginContainer/VBoxContainer/BuildButton
@onready var gather_button = $BuildPanel/MarginContainer/VBoxContainer/GatherButton
@onready var house_button = $BuildPanel/MarginContainer/VBoxContainer/HouseButton
@onready var lumbermill_button = $BuildPanel/MarginContainer/VBoxContainer/LumbermillButton

signal mode_changed(mode: String)
signal building_selected(type: String)

func _ready():
	build_button.pressed.connect(_on_build_button_pressed)
	gather_button.pressed.connect(_on_gather_button_pressed)
	house_button.pressed.connect(_on_house_button_pressed)
	lumbermill_button.pressed.connect(_on_lumbermill_button_pressed)
	
	# Standardmäßig im Sammelmodus starten
	_on_gather_button_pressed()
	
	# Gebäude-Buttons ausblenden
	house_button.visible = false
	lumbermill_button.visible = false

func update_resources(inventory: Dictionary) -> void:
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	fiber_label.text = "Fiber: %d" % inventory["fiber"]

func _on_build_button_pressed():
	build_button.disabled = true
	gather_button.disabled = false
	house_button.visible = true
	lumbermill_button.visible = true
	mode_changed.emit("build")

func _on_gather_button_pressed():
	build_button.disabled = false
	gather_button.disabled = true
	house_button.visible = false
	lumbermill_button.visible = false
	mode_changed.emit("gather")

func _on_house_button_pressed():
	house_button.disabled = true
	lumbermill_button.disabled = false
	building_selected.emit("house")

func _on_lumbermill_button_pressed():
	house_button.disabled = false
	lumbermill_button.disabled = true
	building_selected.emit("lumbermill")
