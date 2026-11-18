class_name ClimateEffect
extends Node
## Clase base para cualquier componente que reaccione al clima emocional.

func _ready() -> void:
	Climate.registrar_efecto(self)
	# Inicialización del estado actual
	aplicar_clima(Climate.display)
	alternar_visuales(Climate.visuals_on)

func _exit_tree() -> void:
	Climate.desregistrar_efecto(self)

## Método virtual a sobrescribir por las subclases
func aplicar_clima(_normalizado: float) -> void:
	push_warning("ClimateEffect: aplicar_clima() debe ser implementado por la subclase.")

## Método virtual a sobrescribir por las subclases
func alternar_visuales(_activo: bool) -> void:
	pass
