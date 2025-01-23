extends StaticBody3D

# Preload häufig verwendeter Materialien
const WOOD_STUMP_MATERIAL = preload("res://materials/wood_stump.tres")
const WOOD_CROWN_MATERIAL = preload("res://materials/wood_crown.tres")
const STONE_MATERIAL = preload("res://materials/stone.tres")
const FOOD_MATERIAL = preload("res://materials/food.tres")

enum ResourceType {WOOD, STONE, FOOD}
@export var resource_type: ResourceType
@export var resource_amount: int = 10
const MAX_HARVEST: int = 3
var remaining_harvests: int = MAX_HARVEST
var is_being_removed: bool = false
@onready var start_position: Vector3 = self.global_position

signal resource_removed(position: Vector3, type: String)

func _ready():
	# Stelle sicher, dass die Kollision aktiviert ist und die richtige Maske hat
	collision_layer = 4  # COLLISION_LAYER_BUILDINGS
	collision_mask = 4   # COLLISION_LAYER_BUILDINGS
	
	# Set the color based on resource type
	match resource_type:
		ResourceType.WOOD:
			# Entferne alte Mesh-Instanz falls vorhanden
			if has_node("MeshInstance3D"):
				$MeshInstance3D.queue_free()
			
			# Erstelle Baumstumpf und Krone
			var stump = CSGCylinder3D.new()
			stump.radius = 0.3
			stump.height = 0.4
			stump.position.y = 0.2  # Halbe Höhe
			add_child(stump)
			stump.material = WOOD_STUMP_MATERIAL
			
			var crown = CSGBox3D.new()
			crown.size = Vector3(1.0, 1.0, 1.0)
			crown.position.y = 1.2  # Über dem Stumpf
			crown.name = "Crown"
			add_child(crown)
			crown.material = WOOD_CROWN_MATERIAL
			
		ResourceType.STONE:
			$MeshInstance3D.material_override = STONE_MATERIAL
		ResourceType.FOOD:
			$MeshInstance3D.material_override = FOOD_MATERIAL

func get_resource_type() -> String:
	match resource_type:
		ResourceType.WOOD:
			return "WOOD"
		ResourceType.STONE:
			return "STONE"
		ResourceType.FOOD:
			return "FOOD"
	return "UNKNOWN"

func gather_resource():
	if is_being_removed:
		return null
		
	remaining_harvests -= 1
	var resource_name = ResourceType.keys()[resource_type].to_lower()
	print("[Resource] Gathered %d units of %s (%d harvests remaining)" % [resource_amount, resource_name, remaining_harvests])
	
	if resource_type != ResourceType.WOOD:
		var new_position = start_position - (start_position.normalized() * (MAX_HARVEST - remaining_harvests) / MAX_HARVEST)
		self.global_position = new_position
	
	if remaining_harvests <= 0:
		is_being_removed = true
		
		if resource_type == ResourceType.WOOD:
			# Entferne nur die Baumkrone
			if has_node("Crown"):
				$Crown.queue_free()
			# Signal senden
			resource_removed.emit(global_position, get_resource_type())
			# Deaktiviere NICHT die Kollision für Baumstümpfe
		else:
			# Für andere Ressourcen: Komplett entfernen
			# Deaktiviere Kollision
			collision_layer = 0
			collision_mask = 0
			await get_tree().create_timer(0.5).timeout
			queue_free()
		
	return {
		"type": resource_name,
		"amount": resource_amount
	}

func regrow_tree():
	if resource_type == ResourceType.WOOD and not has_node("Crown"):
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

func demolish():
	is_being_removed = true
	resource_removed.emit(global_position, get_resource_type())
	# Deaktiviere Kollision
	collision_layer = 0
	collision_mask = 0
	queue_free()
