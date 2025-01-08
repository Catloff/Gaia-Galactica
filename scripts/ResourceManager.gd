extends Node3D

signal resource_changed(resource_type: String, old_value: int, new_value: int)

var inventory = {
	"wood": 100,
	"stone": 100,
	"food": 100,
	"metal": 4,
	"fuel": 0
}

var storage_limits = {
	"wood": 1000,
	"stone": 1000,
	"food": 500,
	"metal": 100,
	"fuel": 200,
}

@onready var hud = $"../HUD"

func can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var required_amount = costs[resource_type]
		if not inventory.has(resource_type) or inventory[resource_type] < required_amount:
			return false
	return true

func pay_cost(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	
	var old_values = {}
	for resource_type in costs:
		old_values[resource_type] = inventory[resource_type]
		inventory[resource_type] -= costs[resource_type]
		resource_changed.emit(resource_type, old_values[resource_type], inventory[resource_type])
	
	return true

func add_resources(resource_data: Dictionary) -> void:
	var resource_type = resource_data["type"].to_lower()
	var amount = resource_data["amount"]
	
	var old_value = inventory[resource_type]
	var new_value = clampi(old_value + amount, 0, storage_limits[resource_type])
	inventory[resource_type] = new_value
	resource_changed.emit(resource_type, old_value, inventory[resource_type])

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.has_method("gather_resource"):
			var resource_data = result.collider.gather_resource()
			if resource_data != null:
				add_resources(resource_data)
