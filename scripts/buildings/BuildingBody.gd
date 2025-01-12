extends StaticBody3D

func demolish():
	# Hole das Hauptgebäude (Parent)
	var building = get_parent()
	if building and building.has_method("demolish"):
		building.demolish()
	else:
		print("[BuildingBody] Fehler: Parent hat keine demolish()-Funktion")