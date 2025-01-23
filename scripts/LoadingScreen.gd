extends Control

@onready var progress_bar = $CenterContainer/VBoxContainer/MarginContainer/ProgressBar
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel
@onready var tip_label = $CenterContainer/VBoxContainer/TipLabel

signal loading_completed

var total_steps := 5
var current_step := 0

var tips = [
	"Tipp: Nutze die rechte Maustaste zum Rotieren der Kamera",
	"Tipp: Holzfäller arbeiten automatisch in ihrem Radius",
	"Tipp: Lagergebäude erhöhen deine maximale Lagerkapazität",
	"Tipp: Große Steine sind unerschöpfliche Ressourcenquellen",
	"Tipp: Platziere Gebäude strategisch nahe beieinander"
]

func _ready():
	progress_bar.max_value = total_steps
	progress_bar.value = 0
	show_random_tip()

func show_random_tip():
	tip_label.text = tips[randi() % tips.size()]

func update_progress(status: String) -> void:
	current_step += 1
	
	# Sanfte Animation des Fortschrittsbalkens
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", current_step, 0.3)
	
	status_label.text = status
	show_random_tip()
	
	if current_step >= total_steps:
		await get_tree().create_timer(0.5).timeout
		
		# Ausblenden mit Animation
		var fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
		await fade_tween.finished
		
		loading_completed.emit()
		queue_free() 