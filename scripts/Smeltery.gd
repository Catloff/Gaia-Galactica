extends Node3D

const BASE_COST = {
	"wood": 80,
	"stone": 40
}

const UPGRADE_COSTS = [
	{
		"metal": 5,
		"stone": 20
	},
	{
		"metal": 10,
		"stone": 40
	}
]

const BASE_PROCESS_TIME = 5.0
const WOOD_COST = 2
const STONE_COST = 1
const BASE_METAL_OUTPUT = 1

var current_level = 1
const MAX_LEVEL = 3
# TODO: use Timer node?
var process_timer = 0.0
var is_active = false

@onready var resource_manager = get_node("/root/Main/ResourceManager")
@onready var upgrade_button = $UI/UpgradeButton
@onready var level_label = $UI/LevelLabel

func _ready():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.3)  # Reddish brown for smeltery
	$MeshInstance3D.material_override = material
	
	# Füge get_cost zum StaticBody3D hinzu
	$StaticBody3D.set_script(preload("res://scripts/SmelteryBody.gd"))

func _process(delta):
	if not is_active:
		return
		
	process_timer += delta
	if process_timer >= get_process_time():
		process_timer = 0.0
		try_produce_metal()

func try_produce_metal():
	var costs = {
		"wood": WOOD_COST,
		"stone": STONE_COST,
	}
	if resource_manager.pay_cost(costs):
		resource_manager.add_resources({
			"type": "metal",
			"amount": get_metal_output()
		})

func get_process_time() -> float:
	# Each level reduces process time by 1 second
	return BASE_PROCESS_TIME - (current_level - 1)

func get_metal_output() -> int:
	# Each level adds 1 to metal output
	return BASE_METAL_OUTPUT + (current_level - 1)

func can_upgrade() -> bool:
	if current_level >= MAX_LEVEL:
		return false
		
	var cost = get_upgrade_cost()
	return resource_manager.can_afford(cost)

func get_upgrade_cost() -> Dictionary:
	if current_level >= MAX_LEVEL:
		return {}
	return UPGRADE_COSTS[current_level - 1]

func upgrade():
	if not can_upgrade():
		return
		
	var cost = get_upgrade_cost()
	
	# Pay upgrade cost
	if resource_manager.pay_cost(cost):
		current_level += 1
		update_ui()
		
		# Update building appearance
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.6 + (current_level - 1) * 0.1, 0.3, 0.3)  # Gets slightly redder with each level
		$MeshInstance3D.material_override = material

func setup_ui():
	var button_position = get_viewport().get_camera_3d().unproject_position(global_transform.origin)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI.set_position(button_position - Vector2(50, -20))
	$UI.set_visible(true)

func update_ui():
	if not level_label or not upgrade_button:
		return
		
	level_label.text = "Level %d" % current_level
	
	if current_level >= MAX_LEVEL:
		upgrade_button.text = "Max Level"
		upgrade_button.disabled = true
	else:
		var cost = get_upgrade_cost()
		upgrade_button.text = "Upgrade (%d Metal, %d Stone)" % [cost["metal"], cost["stone"]]
		upgrade_button.disabled = not can_upgrade()

func _on_upgrade_pressed():
	upgrade()

func _on_resource_changed(resource_type: String, _old_value: int, _new_value: int):
	# Only update UI if the changed resource is one we care about for upgrades
	var upgrade_cost = get_upgrade_cost()
	if upgrade_cost.has(resource_type):
		update_ui()

func activate():
	is_active = true
	
	# Setup UI elements
	setup_ui()
	update_ui()
	
	# Connect to resource manager signal
	resource_manager.resource_changed.connect(_on_resource_changed)

static func get_cost() -> Dictionary:
	return BASE_COST
