extends Node3D

var resources = {
	"wood": 100,
	"stone": 50,
	"food": 100,
	"metal": 0,
	"crystal": 0,
	"energy": 0,
	"fuel": 0
}

var base_storage_capacity = 1000  # Basis-Lagerkapazität
var additional_storage_capacity = 0  # Zusätzliche Kapazität durch Lagergebäude

signal resources_updated

var pending_click_position = null

func _ready():
	resources_updated.emit()

func get_resources() -> Dictionary:
	return resources

func get_resource(type: String) -> int:
	return resources.get(type, 0)

func get_total_storage_capacity() -> int:
	return base_storage_capacity + additional_storage_capacity

func increase_storage_capacity(amount: int):
	additional_storage_capacity += amount
	print("Lagerkapazität erhöht um ", amount, " auf ", get_total_storage_capacity())
	resources_updated.emit()

func decrease_storage_capacity(amount: int):
	additional_storage_capacity = max(0, additional_storage_capacity - amount)
	print("Lagerkapazität verringert um ", amount, " auf ", get_total_storage_capacity())
	
	# Prüfe ob Ressourcen die neue Kapazität überschreiten
	var total_capacity = get_total_storage_capacity()
	for resource in resources:
		if resources[resource] > total_capacity:
			resources[resource] = total_capacity
	resources_updated.emit()

func can_afford(costs: Dictionary) -> bool:
	for resource_type in costs:
		var required_amount = costs[resource_type]
		if not resources.has(resource_type) or resources[resource_type] < required_amount:
			return false
	return true

func pay_cost(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
		
	for resource_type in costs:
		resources[resource_type] -= costs[resource_type]
	
	resources_updated.emit()
	return true

func add_resources(resource_data: Dictionary) -> bool:
	var type = resource_data["type"]
	var amount = resource_data["amount"]
	
	if not resources.has(type):
		resources[type] = 0
	
	# Prüfe ob die Lagerkapazität ausreicht
	var total_capacity = get_total_storage_capacity()
	var new_amount = resources[type] + amount
	
	if new_amount > total_capacity:
		# Wenn nicht genug Platz, fülle nur bis zur Kapazitätsgrenze
		resources[type] = total_capacity
		resources_updated.emit()
		return false
	
	resources[type] = new_amount
	resources_updated.emit()
	return true

func remove_resources(resource_data: Dictionary) -> bool:
	var type = resource_data["type"]
	var amount = resource_data["amount"]
	
	if not resources.has(type) or resources[type] < amount:
		return false
		
	resources[type] -= amount
	resources_updated.emit()
	return true

func has_resources(required_resources: Dictionary) -> bool:
	for resource in required_resources:
		if not resources.has(resource) or resources[resource] < required_resources[resource]:
			return false
	return true

func _input(event):
	# Debug: Zeige Event-Typ
	if event is InputEventScreenTouch:
		if event.pressed:
			pending_click_position = event.position
	elif event is InputEventMouseButton:
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
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			if result.collider.has_method("gather_resource"):
				print("[ResourceManager] Objekt hat gather_resource Methode")
				var resource_data = await result.collider.gather_resource()
				if resource_data != null:
					print("[ResourceManager] Ressource gesammelt: ", resource_data)
					add_resources(resource_data)
			
		pending_click_position = null
