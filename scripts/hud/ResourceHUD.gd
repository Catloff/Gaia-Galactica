extends Control

@onready var wood_label = %WoodLabel
@onready var stone_label = %StoneLabel
@onready var food_label = %FoodLabel
@onready var metal_label = %MetalLabel
@onready var crystal_label = %CrystalLabel
@onready var energy_label = %EnergyLabel
@onready var fuel_label = %FuelLabel

@onready var resource_manager = get_node("/root/Main/ResourceManager")

func _ready():
	# Verbinde das Signal für Ressourcen-Updates
	resource_manager.resources_updated.connect(_on_resources_updated)
	_on_resources_updated()

func _on_resources_updated():
	var resources = resource_manager.get_resources()
	var capacity = resource_manager.get_total_storage_capacity()
	
	if wood_label:
		wood_label.text = "Holz: %d/%d" % [resources["wood"], capacity]
	if stone_label:
		stone_label.text = "Stein: %d/%d" % [resources["stone"], capacity]
	if food_label:
		food_label.text = "Nahrung: %d/%d" % [resources["food"], capacity]
	if metal_label:
		metal_label.text = "Metall: %d/%d" % [resources["metal"], capacity]
	if crystal_label:
		crystal_label.text = "Kristall: %d/%d" % [resources["crystal"], capacity]
	if energy_label:
		energy_label.text = "Energie: %d/%d" % [resources["energy"], capacity]
	if fuel_label:
		fuel_label.text = "Treibstoff: %d/%d" % [resources["fuel"], capacity]
