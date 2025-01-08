extends Node3D

var inventory = {
	"wood": 100,
	"stone": 100,
	"food": 100,
	"metal": 4
}

@onready var hud = get_node("../HUD")

func _ready() -> void:
	call_deferred("update_hud")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.has_method("gather_resource"):
			var resource_data = result.collider.gather_resource()
			if resource_data != null:
				update_inventory(resource_data)

func update_inventory(resource_data):
	var resource_type = resource_data["type"].to_lower()
	var amount = resource_data["amount"]
	
	inventory[resource_type] += amount
	update_hud()

func update_hud():
	if hud:
		hud.update_resources(inventory)
