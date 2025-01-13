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

var pending_click_position = null

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
	# Debug: Zeige Event-Typ
	if event is InputEventScreenTouch:
		print("[ResourceManager] Touch-Event erkannt - pressed: ", event.pressed, " position: ", event.position)
		if event.pressed:
			pending_click_position = event.position
	elif event is InputEventMouseButton:
		print("[ResourceManager] Maus-Event erkannt - pressed: ", event.pressed, " button: ", event.button_index)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pending_click_position = event.position

func _physics_process(_delta):
	if pending_click_position != null:
		print("[ResourceManager] Versuche Ressource zu sammeln...")
		var camera = get_viewport().get_camera_3d()
		if not camera:
			print("[ResourceManager] Keine Kamera gefunden!")
			pending_click_position = null
			return
			
		var from = camera.project_ray_origin(pending_click_position)
		var to = from + camera.project_ray_normal(pending_click_position) * 1000
		print("[ResourceManager] Raycast von: ", from, " nach: ", to)
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			print("[ResourceManager] Raycast Treffer: ", result.collider.name)
			if result.collider.has_method("gather_resource"):
				print("[ResourceManager] Objekt hat gather_resource Methode")
				var resource_data = await result.collider.gather_resource()
				if resource_data != null:
					print("[ResourceManager] Ressource gesammelt: ", resource_data)
					add_resources(resource_data)
				else:
					print("[ResourceManager] Keine Ressourcen erhalten")
			else:
				print("[ResourceManager] Objekt hat KEINE gather_resource Methode")
		else:
			print("[ResourceManager] Kein Raycast Treffer")
			
		pending_click_position = null
