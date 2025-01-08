extends StaticBody3D

const COST = {
	"wood": 50,
	"fiber": 10
}

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1)  # Weiß
	$MeshInstance3D.material_override = material

static func get_cost() -> Dictionary:
	return COST 