extends Node3D

const COST = {
	"wood": 80,
	"stone": 40
}

const PROCESS_TIME = 5.0  # Seconds to create one metal
const WOOD_PER_METAL = 2
const STONE_PER_METAL = 1

@onready var resource_manager = get_node("/root/Main/ResourceManager")
var process_timer = 0.0
var is_active = false

func _ready():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.3)  # Reddish brown for smeltery
	$MeshInstance3D.material_override = material

func _process(delta):
	if not is_active:
		return
		
	process_timer += delta
	if process_timer >= PROCESS_TIME:
		process_timer = 0.0
		try_produce_metal()

func try_produce_metal():
	var inventory = resource_manager.inventory
	if inventory["wood"] >= WOOD_PER_METAL and inventory["stone"] >= STONE_PER_METAL:
		# Consume resources
		inventory["wood"] -= WOOD_PER_METAL
		inventory["stone"] -= STONE_PER_METAL
		# Produce metal
		inventory["metal"] += 1
		resource_manager.update_hud()

func activate():
	is_active = true

static func get_cost() -> Dictionary:
	return COST
