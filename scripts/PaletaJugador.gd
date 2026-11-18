class_name PaletaJugador
extends PaletaBase

# PALETA CONTROLADA POR EL JUGADOR RE PRO
# Hereda posición, velocidad y límites de PaletaBase para que sean igualitas 


# movimiento con el teclado (ya sean las flechitas de arriba y abajo o el W,S)
func actualizar_movimiento(
	delta: float,
	alto_pantalla: float,
	_pelota_y: float,
	_jugando: bool,
	_velocidad_pelota_x: float
) -> void:

	var movimiento: float = 0.0

	# Subir la paletita
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movimiento -= 1.0

	# Bajar la paletita
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movimiento += 1.0

	# Utiliza el metodo que se hereda
	_desplazar(
		movimiento * alto_pantalla * _factor_velocidad * delta,
		alto_pantalla
	)
