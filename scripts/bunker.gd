class_name Bunker
extends EntidadEspacial

@export var resistencia_inicial: int = 4

# Registra el búnker en su grupo y le asigna cuántos golpes aguanta antes de romperse
func _ready() -> void:
	add_to_group("bunkers")
	configurar_vidas(resistencia_inicial)

# Cada vez que le pega un tiro, se oscurece un poco para que se note el desgaste
func recibir_dano(cantidad: int = 1) -> void:
	modulate = modulate.darkened(0.2)
	super.recibir_dano(cantidad)

# Si los aliens bajan demasiado y lo tocan, se destruye al instante
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemigos"):
		destruir()
