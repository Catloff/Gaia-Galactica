extends BaseBuilding

const FOOD_COST = 2
const FUEL_OUTPUT = 1
const BASE_PROCESS_TIME = 5.0

var process_timer = 0.0

func setup_building():
	upgrade_costs = [
		{
			"metal": 10,
			"stone": 20
		},
		{
			"metal": 20,
			"stone": 40
		}
	]
	
	max_level = 3
	
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.6, 0.7)  # Blue-ish for refinery
	$Base.material_override = material

func _process(delta):
	if not is_active:
		return
		
	process_timer += delta
	if process_timer >= get_process_time():
		process_timer = 0.0
		try_produce_fuel()

func try_produce_fuel():
	var costs = {
		"food": FOOD_COST
	}
	
	if resource_manager.pay_cost(costs):
		resource_manager.add_resources({
			"type": "fuel",
			"amount": FUEL_OUTPUT * get_efficiency_multiplier()
		})

func get_process_time() -> float:
	return BASE_PROCESS_TIME / get_speed_multiplier()

func get_efficiency_multiplier() -> float:
	return 1.0 + (0.25 * current_level)  # 25% more output per level

func get_speed_multiplier() -> float:
	return 1.0 + (0.2 * current_level)  # 20% faster per level
