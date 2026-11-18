class_name PaletaBase
extends RefCounted

#BASE DE LA PALETA QUE VA A SER HEREDADA DESPUES

const PROPORCION_ALTO: float = 0.24

# Variables internas (encapsulamiento)
var _posicion_y: float = 0.0
var _factor_velocidad: float = 1.0


# hace que la paletita arranque en el centro de la pantalla
func inicializar(alto_pantalla: float, factor_velocidad: float) -> void:
	_posicion_y = alto_pantalla * 0.5
	_factor_velocidad = factor_velocidad
	_limitar_posicion(alto_pantalla)



func obtener_posicion_y() -> float:
	return _posicion_y


# la altura de ambas paletas para que sean iguales
func obtener_mitad_alto(alto_pantalla: float) -> float:
	return alto_pantalla * PROPORCION_ALTO * 0.5


# esto es para ser sobreescrito por las clases hijas
func actualizar_movimiento(
	_delta: float,
	_alto_pantalla: float,
	_pelota_y: float,
	_jugando: bool,
	_velocidad_pelota_x: float
) -> void:
	pass


# mueve la paletita y delimita los bordes asi no se sale
func _desplazar(desplazamiento: float, alto_pantalla: float) -> void:
	_posicion_y += desplazamiento
	_limitar_posicion(alto_pantalla)


# Acerca la paleta a un objetivo a velocidad limitada.
func _acercarse(
	objetivo_y: float,
	distancia_maxima: float,
	alto_pantalla: float
) -> void:
	_posicion_y = move_toward(
		_posicion_y,
		objetivo_y,
		distancia_maxima
	)
	_limitar_posicion(alto_pantalla)


# para que no se vaya volando a la loca por los bordes
func _limitar_posicion(alto_pantalla: float) -> void:
	var mitad := obtener_mitad_alto(alto_pantalla)

	_posicion_y = clampf(
		_posicion_y,
		mitad,
		alto_pantalla - mitad
	)
