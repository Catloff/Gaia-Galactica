extends StaticBody3D

enum ResourceType {WOOD, FIBER, FOOD}
@export var resource_type: ResourceType
@export var resource_amount: int = 10
var remaining_harvests: int = 3
var is_being_removed: bool = false

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
	update_appearance()

func get_resource_type() -> String:
	return ResourceType.keys()[resource_type]

func gather_resource():
	if is_being_removed:
		return null
		
	remaining_harvests -= 1
	var resource_name = ResourceType.keys()[resource_type].to_lower()
	print("Player gathered %d units of %s (%d harvests remaining)" % [resource_amount, resource_name, remaining_harvests])
	
	update_appearance()
	
	if remaining_harvests <= 0:
		is_being_removed = true
		# Deaktiviere Kollision sofort
		collision_layer = 0
		collision_mask = 0
		# Kurze Verzögerung vor dem Entfernen für visuelles Feedback
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(func(): queue_free())
		
	return {
		"type": resource_name,
		"amount": resource_amount
	}

func update_appearance():
	if not $MeshInstance3D.material_override:
		return
		
	# Ressource wird transparenter je weniger Ernten übrig sind
	var alpha = 0.4 + (remaining_harvests / 3.0) * 0.6
	var material = $MeshInstance3D.material_override.duplicate()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = alpha
	$MeshInstance3D.material_override = material
