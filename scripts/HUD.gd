extends Control

@onready var wood_label = $ResourcePanel/MarginContainer/Resources/WoodLabel
@onready var food_label = $ResourcePanel/MarginContainer/Resources/FoodLabel
@onready var fiber_label = $ResourcePanel/MarginContainer/Resources/FiberLabel

func update_resources(inventory: Dictionary) -> void:
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	fiber_label.text = "Fiber: %d" % inventory["fiber"]
