class_name CamaraJuego
extends Camera2D

var _fuerza_shake: float = 0.0

# Si teimbla, mueve la cámara de manera random y la va frenando suavemente hasta volver al centro
func _process(delta: float) -> void:
	if _fuerza_shake > 0.0:
		_fuerza_shake = lerpf(_fuerza_shake, 0.0, 5.0 * delta)
		offset = Vector2(
			randf_range(-_fuerza_shake, _fuerza_shake),
			randf_range(-_fuerza_shake, _fuerza_shake)
		)
	else:
		offset = Vector2.ZERO

# Arranca el temblor de pantalla con la fuerza que le pasemos
func aplicar_shake(fuerza: float) -> void:
	_fuerza_shake = fuerza
