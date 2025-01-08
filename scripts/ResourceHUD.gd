extends Control

@onready var wood_label = $MarginContainer/Resources/WoodLabel
@onready var food_label = $MarginContainer/Resources/FoodLabel
@onready var stone_label = $MarginContainer/Resources/StoneLabel
@onready var metal_label = $MarginContainer/Resources/MetalLabel
@onready var resource_manager = get_node("/root/Main/ResourceManager")

func _ready() -> void:
	resource_manager.resource_changed.connect(update_resources)
	update_resources(null, null, null)

func update_resources(_type, _old_value, _new_value) -> void:
	var inventory = resource_manager.inventory
	wood_label.text = "Wood: %d" % inventory["wood"]
	food_label.text = "Food: %d" % inventory["food"]
	stone_label.text = "Stone: %d" % inventory["stone"]
	metal_label.text = "Metal: %d" % inventory["metal"]
