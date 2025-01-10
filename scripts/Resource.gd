extends StaticBody3D

enum ResourceType {WOOD, STONE, FOOD}
@export var resource_type: ResourceType
@export var resource_amount: int = 10
var remaining_harvests: int = 3
var is_being_removed: bool = false

signal resource_removed(position: Vector3, type: String)

func _ready():
	# Stelle sicher, dass die Kollision aktiviert ist
	collision_layer = 1
	collision_mask = 1
	
	# Set the color based on resource type
	var material = StandardMaterial3D.new()
	
	match resource_type:
		ResourceType.WOOD:
			print("[Resource] Erstelle neuen Baum")
			# Erstelle Baumstumpf und Krone
			var stump = CSGCylinder3D.new()
			stump.radius = 0.3
			stump.height = 0.4
			
			stump.position.y = 0.2  # Halbe Höhe
			add_child(stump)
			
			var stump_material = StandardMaterial3D.new()
			
			stump_material.albedo_color = Color(0.4, 0.3, 0.2)  # Braun für Holz
			stump.material = stump_material
			
			var crown = CSGBox3D.new()
			crown.size = Vector3(1.0, 1.0, 1.0)
			crown.position.y = 1.2  # Über dem Stumpf
			crown.name = "Crown"
			add_child(crown)
			
			var crown_material = StandardMaterial3D.new()
			crown_material.albedo_color = Color(0.2, 0.6, 0.2)  # Grün für Blätter
			crown.material = crown_material
			
		ResourceType.STONE:
			material.albedo_color = Color(0.7, 0.7, 0.7) # Gray
			$MeshInstance3D.material_override = material
		ResourceType.FOOD:
			material.albedo_color = Color(0.8, 0.0, 0.0) # Red
			$MeshInstance3D.material_override = material

func get_resource_type() -> String:
	return ResourceType.keys()[resource_type]

func gather_resource():
	if is_being_removed:
		return null
		
	remaining_harvests -= 1
	var resource_name = ResourceType.keys()[resource_type].to_lower()
	print("[Resource] Gathered %d units of %s (%d harvests remaining)" % [resource_amount, resource_name, remaining_harvests])
	
	if remaining_harvests <= 0:
		is_being_removed = true
		
		if resource_type == ResourceType.WOOD:
			print("[Resource] Entferne Baumkrone")
			# Entferne nur die Baumkrone
			if has_node("Crown"):
				$Crown.queue_free()
			# Signal senden
			resource_removed.emit(global_position, get_resource_type())
			# Deaktiviere NICHT die Kollision für Baumstümpfe
		else:
			# Für andere Ressourcen: Komplett entfernen
			print("[Resource] Entferne komplette Ressource")
			# Deaktiviere Kollision
			collision_layer = 0
			collision_mask = 0
			queue_free()
		
	return {
		"type": resource_name,
		"amount": resource_amount
	}

func regrow_tree():
	if resource_type == ResourceType.WOOD and not has_node("Crown"):
		print("[Resource] Lasse Baum nachwachsen")
		# Erstelle neue Krone
		var crown = CSGBox3D.new()
		crown.size = Vector3(1.0, 1.0, 1.0)
		crown.position.y = 1.2  # Über dem Stumpf
		crown.name = "Crown"
		
		var crown_material = StandardMaterial3D.new()
		crown_material.albedo_color = Color(0.2, 0.6, 0.2)  # Grün für Blätter
		crown.material = crown_material
		
		add_child(crown)
		
		is_being_removed = false
		remaining_harvests = 3
		print("[Resource] Baum ist nachgewachsen")
