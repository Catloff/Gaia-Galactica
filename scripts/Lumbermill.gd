extends StaticBody3D

const COST = {
	"wood": 60
}

const HARVEST_RADIUS = 2.0
const HARVEST_RATE = 1.0  # Sekunden pro Ernte

@onready var resource_manager = get_node("/root/Main/ResourceManager")
var harvest_timer: float = 0.0

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)  # Braun
	$MeshInstance3D.material_override = material

func _process(delta):
	harvest_timer += delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		harvest_nearby_wood()

func harvest_nearby_wood():
	var space_state = get_world_3d().direct_space_state
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = HARVEST_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	
	var results = space_state.intersect_shape(query_params)
	for result in results:
		var collider = result["collider"]
		if collider.has_method("gather_resource"):
			var resource_data = collider.gather_resource()
			if resource_data["type"].to_lower() == "wood":
				resource_manager.update_inventory(resource_data)
				return  # Nur eine Ressource pro Tick ernten

static func get_cost() -> Dictionary:
	return COST 