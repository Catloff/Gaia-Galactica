extends Control

@onready var wood_label = $MarginContainer/Resources/WoodLabel
@onready var food_label = $MarginContainer/Resources/FoodLabel
@onready var stone_label = $MarginContainer/Resources/StoneLabel
@onready var metal_label = $MarginContainer/Resources/MetalLabel
@onready var fuel_label = $MarginContainer/Resources/FuelLabel
@onready var resource_manager = get_node("/root/Main/ResourceManager")

func _ready() -> void:
	resource_manager.resource_changed.connect(update_resources)
	update_resources(null, null, null)

func update_resources(_type, _old_value, _new_value) -> void:
	var inventory = resource_manager.inventory
	var limits = resource_manager.storage_limits
	wood_label.text = "Wood: %d/%d" % [inventory["wood"], limits["wood"]]
	food_label.text = "Food: %d/%d" % [inventory["food"], limits["food"]]
	stone_label.text = "Stone: %d/%d" % [inventory["stone"], limits["stone"]]
	metal_label.text = "Metal: %d/%d" % [inventory["metal"], limits["metal"]]
	fuel_label.text = "Fuel: %d/%d" % [inventory["fuel"], limits["fuel"]]
