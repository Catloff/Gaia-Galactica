extends BaseBuilding

const HARVEST_RADIUS = 5.0
const HARVEST_RATE = 1.0  # Sekunden pro Ernte

var harvest_timer: float = 0.0

@onready var base_mesh = %Base
@onready var saw_mesh = %Saw

func _setup_building():
	# Set building color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)  # Braun für Sägewerk
	base_mesh.material_override = material
	
	var saw_material = StandardMaterial3D.new()
	saw_material.albedo_color = Color(0.7, 0.7, 0.7)  # Silber für die Säge
	saw_mesh.material_override = saw_material

func _process(_delta):
	if not is_active:
		return
		
	harvest_timer += _delta
	if harvest_timer >= HARVEST_RATE:
		harvest_timer = 0.0
		_try_harvest_wood()
		
	# Rotiere die Säge
	if saw_mesh:
		saw_mesh.rotate_z(_delta * 2.0)

# Wrapper-Funktion für Fehlerbehandlung
func _try_harvest_wood() -> void:
	if not is_instance_valid(self):
		return
	harvest_nearby_wood()

func harvest_nearby_wood() -> void:
	if not is_instance_valid(self):
		return
		
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	var query_params = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = HARVEST_RADIUS
	query_params.shape = shape
	query_params.transform = global_transform
	
	var results = space_state.intersect_shape(query_params)
	if results.is_empty():
		return  # Keine Ressourcen in Reichweite
		
	for result in results:
		if not "collider" in result:
			continue
			
		var collider = result["collider"]
		if not is_instance_valid(collider):
			continue  # Überspringe ungültige Collider
			
		if not (collider.has_method("gather_resource") and collider.has_method("get_resource_type")):
			continue
			
		# Prüfe erst den Ressourcentyp
		if collider.get_resource_type() == "WOOD":
			var resource_data = await collider.gather_resource()
			if resource_data != null:
				resource_manager.add_resources(resource_data)
				return  # Nur eine Ressource pro Tick ernten
