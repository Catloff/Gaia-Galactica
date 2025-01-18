extends StaticBody3D

func demolish():
	# Hole das Hauptgebäude (Parent)
	var building = get_parent()
	if building and building.has_method("demolish") and building.get_script():
		# Prüfe ob das Parent-Node ein echtes Gebäude ist (hat ein Skript)
		building.demolish()
	else:
		print("[BuildingBody] Fehler: Parent ist kein gültiges Gebäude")