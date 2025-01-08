extends StaticBody3D

const COST = {
	"wood": 10
}

var is_preview: bool = true

func _ready():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.25, 0.0)  # Braun wie normale Bäume
	if is_preview:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.5
	$MeshInstance3D.material_override = material

func activate():
	is_preview = false
	# Erstelle eine echte Ressource an dieser Position
	var resource_scene = load("res://scenes/Resource.tscn")
	var tree = resource_scene.instantiate()
	tree.resource_type = 0  # WOOD type
	get_parent().add_child(tree)
	tree.global_position = global_position
	# Entferne die Vorschau
	queue_free()
