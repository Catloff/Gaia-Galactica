extends Node3D

const GROWTH_TIME = 30.0  # Sekunden bis zur vollen Größe
const MIN_SCALE = 0.2
const MAX_SCALE = 1.0

var growth_timer: float = 0.0
var grow_speed: float = 1.0  # Wird vom Förster gesetzt

@onready var trunk = %Trunk
@onready var crown = %Crown

func _ready():
	# Starte mit minimaler Größe
	scale = Vector3.ONE * MIN_SCALE
	
	# Setze Materialien
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.3, 0.2)  # Braun für den Stamm
	trunk.material_override = trunk_material
	
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color(0.2, 0.5, 0.2)  # Grün für die Krone
	crown.material_override = crown_material

func _process(delta):
	if growth_timer < GROWTH_TIME:
		growth_timer += delta * grow_speed
		var growth_factor = growth_timer / GROWTH_TIME
		var current_scale = lerp(MIN_SCALE, MAX_SCALE, growth_factor)
		scale = Vector3.ONE * current_scale
