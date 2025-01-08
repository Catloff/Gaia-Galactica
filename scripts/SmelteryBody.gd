extends StaticBody3D

func get_cost() -> Dictionary:
	return get_parent().get_cost()

func demolish():
	get_parent().queue_free() 
