extends Control

@onready var resource_hud = $ResourceHUD
@onready var building_hud = $BuildingHUD
@onready var mobile_navigation = $MobileNavigation

signal building_selected(type: String)
signal demolish_mode_changed(enabled: bool)

func _ready():
	building_hud.building_selected.connect(func(type): building_selected.emit(type))
	mobile_navigation.demolish_mode_changed.connect(func(enabled): demolish_mode_changed.emit(enabled))
