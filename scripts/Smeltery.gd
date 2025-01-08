extends BaseBuilding

const WOOD_COST = 2
const STONE_COST = 1
const BASE_METAL_OUTPUT = 1
const BASE_PROCESS_TIME = 5.0

var process_timer = 0.0

func setup_building():
	print("[Smeltery] Setup Building Start")
	base_cost = {
		"wood": 80,
		"stone": 40
	}
	
	upgrade_costs = [
		{
			"metal": 5,
			"stone": 20
		},
		{
			"metal": 10,
			"stone": 40
		}
	]
	
	max_level = 3
	print("[Smeltery] Setup abgeschlossen - Upgrade Kosten: ", upgrade_costs)
	print("[Smeltery] Max Level gesetzt auf: ", max_level)
	
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.3, 0.3)  # Reddish brown for smeltery
	$MeshInstance3D.material_override = material

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

func _on_upgrade():
	print("[Smeltery] Upgrade durchgeführt - Neues Level: ", current_level)
	# Update building appearance
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6 + (current_level - 1) * 0.1, 0.3, 0.3)  # Gets slightly redder with each level
	$MeshInstance3D.material_override = material
