extends StaticBody3D

signal resource_gathered(amount: int)

const RESOURCE_TYPE = "STONE"
const RESOURCE_AMOUNT = 5
const COOLDOWN_TIME = 3.0  # Sekunden zwischen den Abbaumöglichkeiten

var can_be_mined = true
var cooldown_timer = 0.0

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.4)  # Dunkelgrau
	$MeshInstance3D.material_override = material

func _process(delta):
	if not can_be_mined:
		cooldown_timer += delta
		if cooldown_timer >= COOLDOWN_TIME:
			can_be_mined = true
			cooldown_timer = 0.0

func gather_resource():
	if not can_be_mined:
		return null
		
	can_be_mined = false
	
	return {
		"type": RESOURCE_TYPE.to_lower(),
		"amount": RESOURCE_AMOUNT
	}

func get_resource_type() -> String:
	return RESOURCE_TYPE 