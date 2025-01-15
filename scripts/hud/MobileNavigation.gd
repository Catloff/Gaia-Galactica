extends Control

@onready var build_button = $NavigationBar/MarginContainer/ButtonContainer/BuildButton
@onready var demolish_button = $NavigationBar/MarginContainer/ButtonContainer/DemolishButton
@onready var building_hud = $"../BuildingHUD"

signal demolish_mode_changed(enabled: bool)

func _ready():
	build_button.pressed.connect(_on_build_button_pressed)
	demolish_button.pressed.connect(_on_demolish_button_pressed)
	if building_hud:
		building_hud.hide()
		building_hud.menu_closed.connect(_on_building_hud_closed)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if demolish_button.button_pressed:
				demolish_button.button_pressed = false
				_on_demolish_button_pressed()
			elif build_button.button_pressed:
				build_button.button_pressed = false
				_on_build_button_pressed()

func _on_build_button_pressed():
	if not building_hud:
		return
		
	if building_hud.visible:
		building_hud.hide()
	else:
		building_hud.show()
		# Deaktiviere den Abriss-Modus wenn das Baumenü geöffnet wird
		if demolish_button.button_pressed:
			demolish_button.button_pressed = false
			demolish_mode_changed.emit(false)
		
	# Synchronisiere BuildingHUD-Sichtbarkeit mit Button-Status
	build_button.button_pressed = building_hud.visible

func _on_demolish_button_pressed():
	if building_hud and building_hud.visible:
		building_hud.hide()
		build_button.button_pressed = false
	demolish_mode_changed.emit(demolish_button.button_pressed)

func _on_building_hud_closed():
	if build_button:
		build_button.button_pressed = false 
