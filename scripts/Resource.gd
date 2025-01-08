extends StaticBody3D

enum ResourceType {WOOD, FIBER, FOOD}
@export var resource_type: ResourceType
@export var resource_amount: int = 10

func _ready():
	# Set the color based on resource type
	var material = StandardMaterial3D.new()
	
	match resource_type:
		ResourceType.WOOD:
			material.albedo_color = Color(0.5, 0.25, 0.0) # Brown
		ResourceType.FIBER:
			material.albedo_color = Color(0.0, 0.8, 0.0) # Green
		ResourceType.FOOD:
			material.albedo_color = Color(0.8, 0.0, 0.0) # Red
	
	$MeshInstance3D.material_override = material

func gather_resource():
	var resource_name = ResourceType.keys()[resource_type].to_lower()
	print("Player gathered %d units of %s" % [resource_amount, resource_name])
	return {
		"type": resource_name,
		"amount": resource_amount
	}
