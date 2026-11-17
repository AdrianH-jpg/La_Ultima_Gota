## Efecto visual y sonoro de explosión que se autodestruye al finalizar.
class_name EfectoExplosion
extends Node2D

@onready var _sonido: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var _particulas: CPUParticles2D = $CPUParticles2D

# Dispara las partículas y el audio apenas aparece, y se borra solo cuando termina el sonido
func _ready() -> void:
	_sonido.play()
	_particulas.restart()
	_particulas.emitting = true
	
	await _sonido.finished
	queue_free()
