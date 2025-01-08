extends StaticBody3D

signal resource_removed(position: Vector3, type: String)

const RESOURCE_TYPE = "FOOD"
const RESOURCE_AMOUNT = 3  # Etwas weniger als der große Stein
const COOLDOWN_TIME = 2.0  # Etwas schneller als der große Stein

var can_be_harvested = true
var cooldown_timer = 0.0

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 0.2)  # Dunkelgrün für den Busch
	$MeshInstance3D.material_override = material

func _process(delta):
	if not can_be_harvested:
		cooldown_timer += delta
		if cooldown_timer >= COOLDOWN_TIME:
			can_be_harvested = true
			cooldown_timer = 0.0

func gather_resource():
	if not can_be_harvested:
		return null
		
	can_be_harvested = false
	resource_removed.emit(global_position, get_resource_type())
	
	return {
		"type": RESOURCE_TYPE.to_lower(),
		"amount": RESOURCE_AMOUNT
	}

func get_resource_type() -> String:
	return RESOURCE_TYPE 
