extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var fiber_label = $ResourcePanel/MarginContainer/Resources/FiberLabel
@onready var build_button = $BuildPanel/MarginContainer/VBoxContainer/BuildButton
@onready var gather_button = $BuildPanel/MarginContainer/VBoxContainer/GatherButton

signal mode_changed(mode: String)

func _ready():
	build_button.pressed.connect(_on_build_button_pressed)
	gather_button.pressed.connect(_on_gather_button_pressed)
	# Standardmäßig im Sammelmodus starten
	_on_gather_button_pressed()

func update_resources(inventory: Dictionary) -> void:
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	fiber_label.text = "Fiber: %d" % inventory["fiber"]

func _on_build_button_pressed():
	build_button.disabled = true
	gather_button.disabled = false
	mode_changed.emit("build")

func _on_gather_button_pressed():
	build_button.disabled = false
	gather_button.disabled = true
	mode_changed.emit("gather")
