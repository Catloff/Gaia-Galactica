extends Node3D

func _ready():
	setup_camera()
	spawn_resources()

func setup_camera():
	var camera = $Camera3D
	if camera:
		camera.position = Vector3(10, 10, 10)
		camera.look_at(Vector3.ZERO)

func spawn_resources():
	var resource_scene = preload("res://scenes/Resource.tscn")
	
	# Spawn some resources in a grid pattern
	for i in range(-2, 3):
		for j in range(-2, 3):
			var resource = resource_scene.instantiate()
			# Randomly assign resource type
			resource.resource_type = randi() % 3  # 0 to 2 for our three resource types
			add_child(resource)
			resource.position = Vector3(i * 2, 0, j * 2)
